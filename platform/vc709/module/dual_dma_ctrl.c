//
// Copyright (C) 2014 David de la Chevallerie, TU Darmstadt
//
// This file is part of ThreadPoolComposer (TPC).
//
// ThreadPoolComposer is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ThreadPoolComposer is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with ThreadPoolComposer.  If not, see <http://www.gnu.org/licenses/>.
//
/**
 * @file dual_dma_ctrl.c 
 * @brief Implementation of custom dma engine specific code
	Strips the layout of the dma-registers and setup stuff to start a dma transfer
	in addition calls to acknowledge the interrupt in hw is given
 * */

/******************************************************************************/

#include "common/dma_ctrl.h"

/******************************************************************************/

/* Register Map and commands */
#define REG_HOST_ADDR_LOW 	0x00 	/* slv_reg0 = PCIe addr (under) */
#define REG_HOST_ADDR_HIGH 	0x04	/* slv_reg1 = PCIe addr (upper) */
#define REG_FPGA_ADDR_LOW 	0x08	/* slv_reg2 = FPGA addr */
#define REG_BTT 			0x10	/* slv_reg4 = bytes to transfer */
#define REG_ID 				0x14	/* slv_reg5 = ID */
#define REG_CMD 			0x18	/* slv_reg6 = CMD */
#define REG_STATUS 			0x20	/* slv_reg8 = return status */

#define CMD_READ	0x10001000 		/* from m32 fpga memory to m64 host memory */
#define CMD_WRITE	0x10000001 		/* from m64 host memory to m32 fpga memory */
#define CMD_ACK		0x10011001 		/* acknowledge data transfer to toggle interrupt */

/* mutex to sequentialize access to dma registers */
//static DEFINE_MUTEX(dma_regs_mutex);

/******************************************************************************/
/* functions for irq-handling */

/**
 * @brief Acknowledge interrupt in hardware and wake up corresponding process
 * @param i minor node corresponding to this irq
 * @return none
 * */
void ack_irq(int i)
{
	fflink_info("Handle device number %d\n", i);
	/* ack interrupt */
	pcie_writel(CMD_ACK, get_dev_addr(i) + REG_CMD);
	/* Set priv data for more minor nodes accordingly */
	wake_up_queue(i);
}

/**
 * @brief Interrupt handler for dma engine 0
 * @param irq Interrupt number of calling line
 * @param dev_id magic number for interrupt sharing (not needed)
 * @return Tells OS, that irq is handled properly
 * */
irqreturn_t intr_handler_dma_0(int irq, void * dev_id)
{
	fflink_info("Interrupt called with irq %d\n", irq);
	ack_irq(0);
	
	return IRQ_HANDLED;
}

/**
 * @brief Interrupt handler for dma engine 1
 * @param irq Interrupt number of calling line
 * @param dev_id magic number for interrupt sharing (not needed)
 * @return Tells OS, that irq is handled properly
 * */
irqreturn_t intr_handler_dma_1(int irq, void * dev_id)
{
	fflink_info("Interrupt called with irq %d\n", irq);
	ack_irq(1);
	
	return IRQ_HANDLED;
}

/**
 * @brief Interrupt handler for dma engine 2
 * @param irq Interrupt number of calling line
 * @param dev_id magic number for interrupt sharing (not needed)
 * @return Tells OS, that irq is handled properly
 * */
irqreturn_t intr_handler_dma_2(int irq, void * dev_id)
{
	fflink_info("Interrupt called with irq %d\n", irq);
	ack_irq(2);
	
	return IRQ_HANDLED;
}

/**
 * @brief Interrupt handler for dma engine 3
 * @param irq Interrupt number of calling line
 * @param dev_id magic number for interrupt sharing (not needed)
 * @return Tells OS, that irq is handled properly
 * */
irqreturn_t intr_handler_dma_3(int irq, void * dev_id)
{
	fflink_info("Interrupt called with irq %d\n", irq);
	ack_irq(3);
	
	return IRQ_HANDLED;
}

/******************************************************************************/

/**
 * @brief Sets register of dma_engine to start a transfer from FPGA to Main memory
 * @param device_buffer FPGA memory address
 * @param host_handle Handle for platform independent memory address
 * @param btt Bytes to transfer
 * @param device_base_addr Address of dma engine registers
 * @return none
 * */
void transmit_from_device(void * device_buffer, dma_addr_t host_handle, int btt, void * device_base_addr)
{
	fflink_info("dev_buf %lX dma_handle %lX \nsize %d dev_base %lX\n", (unsigned long) device_buffer, (unsigned long) host_handle, btt, (unsigned long) device_base_addr);
	//if(mutex_lock_interruptible(&dma_regs_mutex))
	//	fflink_warn("got killed while aquiring the mutex\n");
		
	/* SA */
	pcie_writel((unsigned long) device_buffer, device_base_addr + REG_FPGA_ADDR_LOW);
	/* DA */
	pcie_writel(host_handle, device_base_addr + REG_HOST_ADDR_LOW);
	/* btt */
	pcie_writel(btt, device_base_addr + REG_BTT);
	/* presvious data have to be written first */
	wmb();
	/* start cmd */
	pcie_writel(CMD_READ, device_base_addr + REG_CMD);
	
	//mutex_unlock(&dma_regs_mutex);
}

/**
 * @brief Sets register of dma_engine to start a transfer from Main memory to FPGA
 * @param device_buffer FPGA memory address
 * @param host_handle Handle for platform independent memory address
 * @param btt Bytes to transfer
 * @param device_base_addr Address of dma engine registers
 * @return none
 * */
void transmit_to_device(void * device_buffer, dma_addr_t host_handle, int btt, void * device_base_addr)
{
	fflink_info("dev_buf %lX dma_handle %lX \nsize %d dev_base %lX\n", (unsigned long) device_buffer, (unsigned long) host_handle, btt, (unsigned long) device_base_addr);
	//if(mutex_lock_interruptible(&dma_regs_mutex))
	//	fflink_warn("got killed while aquiring the mutex\n");
	
	/* SA */
	pcie_writel(host_handle, device_base_addr + REG_HOST_ADDR_LOW);
	/* DA */
	pcie_writel((unsigned long) device_buffer, device_base_addr + REG_FPGA_ADDR_LOW);
	/* btt */
	pcie_writel(btt, device_base_addr + REG_BTT);
	/* presvious data have to be written first */
	wmb();
	/* start cmd */
	pcie_writel(CMD_WRITE, device_base_addr + REG_CMD);
	
	//mutex_unlock(&dma_regs_mutex);
}

/******************************************************************************/
