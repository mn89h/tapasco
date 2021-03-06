/**
 *  @file MonitorScreen.hpp
 *  @brief  Register monitor screen for tapasco-debug.
 *  @author J. Korinth, TU Darmstadt (jk@esa.cs.tu-darmstadt.de)
 **/
#ifndef MONITOR_SCREEN_HPP__
#define MONITOR_SCREEN_HPP__

#include "MenuScreen.hpp"
#include <tapasco.hpp>

class MonitorScreen : public MenuScreen {
public:
  MonitorScreen(Tapasco *tapasco)
      : MenuScreen("TaPaSCo Monitor", vector<string>()), tapasco(*tapasco) {
    delay_us = 250;
    int r = check_bitstream();
    if (r)
      throw r;
  }
  virtual ~MonitorScreen() {
    for (slot_t *sp : slots)
      delete sp;
  }

protected:
  virtual void render() {
    constexpr int rowc = 5 + NUM_ARGS * 2;
    constexpr int colc = 16;
    const int h = (rows - 3) / rowc;
    const int w = cols / colc;
    int start_row = (rows - 3 - h * rowc) / 2;
    int start_col = (cols - w * colc) / 2;
    int sid = 0;
    int y = h;
    for (const slot_t *sp : slots) {
      render_slot(sp, start_row, start_col);
      if (--y > 0)
        start_row += rowc;
      else {
        y = h;
        start_col += colc;
        start_row = (rows - 3 - h * rowc) / 2;
      }
      ++sid;
      if (sid >= h * w)
        break;
    }
    // render keyboard hints
    attron(A_REVERSE);
    mvprintw(rows - 1, cols / 2 - 24,
             "press 'r' for peek, 'p' for poke, 'w' for poke and wait");
    attroff(A_REVERSE);
  }

  virtual int perform(const int choice) {
    if (static_cast<char>(choice) == 'r')
      return peek();
    if (static_cast<char>(choice) == 'p')
      return poke();
    if (static_cast<char>(choice) == 'w')
      return poke_and_wait();
    if (choice == ERR)
      delay();
    return choice;
  }

  virtual void update() {
    for (uint32_t intc = 0; intc < intc_addr.size(); ++intc) {
      if (platform_read_ctl(tapasco.platform_device(), intc_addr[intc],
                            sizeof(intc_isr[intc]), &intc_isr[intc],
                            PLATFORM_CTL_FLAGS_NONE) != PLATFORM_SUCCESS) {
        intc_isr[intc] = 0xDEADBEEF;
      }
    }
    for (slot_t *sp : slots) {
      if (platform_read_ctl(tapasco.platform_device(), sp->base_addr + 0x0c, 4,
                            &sp->isr,
                            PLATFORM_CTL_FLAGS_NONE) != PLATFORM_SUCCESS) {
        sp->isr = 0xDEADBEEF;
      }
      if (platform_read_ctl(tapasco.platform_device(), sp->base_addr + 0x10, 4,
                            &sp->retval[0],
                            PLATFORM_CTL_FLAGS_NONE) != PLATFORM_SUCCESS) {
        sp->retval[0] = 0xDEADBEEF;
      }
      if (platform_read_ctl(tapasco.platform_device(), sp->base_addr + 0x14, 4,
                            &sp->retval[1],
                            PLATFORM_CTL_FLAGS_NONE) != PLATFORM_SUCCESS) {
        sp->retval[1] = 0xDEADBEEF;
      }
      for (int i = 0; i < NUM_ARGS; ++i) {
        for (int j = 0; j < 2; ++j) {
          if (platform_read_ctl(tapasco.platform_device(),
                                sp->base_addr + 0x20 + 0x10 * i + 0x04 * j, 4,
                                &sp->argval[i * 2 + j],
                                PLATFORM_CTL_FLAGS_NONE) != PLATFORM_SUCCESS) {
            sp->argval[i * 2 + j] = 0xDEADBEEF;
          }
        }
      }
    }
  }

private:
  static constexpr int NUM_ARGS{5};
  struct slot_t {
    uint32_t slot_id;
    uint32_t id;
    uint32_t isr;
    uint32_t retval[2];
    uint32_t argval[NUM_ARGS * 2];
    platform_ctl_addr_t base_addr;
  };

  void render_slot(const slot_t *slot, int start_row, int start_col) {
    attron(A_REVERSE);
    mvprintw(start_row++, start_col, "#  : %10u ", slot->slot_id);
    mvprintw(start_row, start_col, "ID :");
    attroff(A_REVERSE);
    mvprintw(start_row++, start_col + 4, "%11u", slot->id);
    attron(A_REVERSE);
    mvprintw(start_row, start_col, "ISR:");
    attroff(A_REVERSE);
    if (slot->isr)
      attron(COLOR_PAIR(1));
    mvprintw(start_row++, start_col + 4, "   %8u", slot->isr);
    if (slot->isr)
      attroff(COLOR_PAIR(1));
    attron(A_REVERSE);
    mvprintw(start_row, start_col, "RET:");
    attroff(A_REVERSE);
    mvprintw(start_row++, start_col + 4, " 0x%08x", slot->retval[0]);
    mvprintw(start_row++, start_col + 4, " 0x%08x", slot->retval[1]);
    for (int i = 0; i < NUM_ARGS; ++i) {
      attron(A_REVERSE);
      mvprintw(start_row, start_col, "A#%u:", i);
      attroff(A_REVERSE);
      mvprintw(start_row++, start_col + 4, " 0x%08x", slot->argval[i * 2]);
      mvprintw(start_row++, start_col + 4, " 0x%08x", slot->argval[i * 2 + 1]);
    }
  }

  int peek() {
    char tmp[255];
    platform_ctl_addr_t addr{0x43c0000c};
    uint32_t val{0};
    int c = ERR;
    clear();
    nocbreak();
    timeout(-1);
    attron(A_REVERSE);
    mvprintw(rows / 2, (cols - 25) / 2, "Address:  ");
    attroff(A_REVERSE);
    echo();
    getstr(tmp);
    noecho();
    cbreak();
    addr = strtoul(tmp, NULL, 0);
    mvprintw(rows / 2, (cols - 25) / 2 + 10, "0x%08x", addr);
    attron(A_REVERSE);
    mvprintw(rows / 2 + 1, (cols - 25) / 2, "Value:    ");
    mvprintw(rows / 2 + 2, (cols - 25) / 2, "OK to peek (y/n)?");
    attroff(A_REVERSE);
    char chr = static_cast<char>(c);
    do {
      c = getch();
      chr = static_cast<char>(c);
      if (chr == 'y') {
        platform_read_ctl(tapasco.platform_device(), addr, sizeof(val), &val,
                          PLATFORM_CTL_FLAGS_NONE);
        mvprintw(rows / 2 + 1, (cols - 25) / 2 + 10, "0x%08x", val);
        mvprintw(rows / 2 + 2, (cols - 25) / 2, "                 ");
      }
    } while (c == ERR || chr == 'y');
    cbreak();
    noecho();
    clear();
    return ERR;
  }

  int poke() {
    char tmp[255];
    platform_ctl_addr_t addr{0x43c0000c};
    uint32_t val{0};
    int c;
    clear();
    nocbreak();
    timeout(-1);
    echo();
    attron(A_REVERSE);
    mvprintw(rows / 2, (cols - 25) / 2, "Address:  ");
    attroff(A_REVERSE);
    getstr(tmp);
    addr = strtoul(tmp, NULL, 0);
    mvprintw(rows / 2, (cols - 25) / 2 + 10, "0x%08x", addr);
    attron(A_REVERSE);
    mvprintw(rows / 2 + 1, (cols - 25) / 2, "Value:    ");
    attroff(A_REVERSE);
    getstr(tmp);
    val = strtoul(tmp, NULL, 0);
    mvprintw(rows / 2 + 1, (cols - 25) / 2 + 10, "0x%08x", val);
    attron(A_REVERSE);
    mvprintw(rows / 2 + 2, (cols - 25) / 2, "OK to poke (y/n)?");
    cbreak();
    timeout(0);
    noecho();
    do {
      c = getch();
      char chr = static_cast<char>(c);
      if (chr == 'y')
        platform_write_ctl(tapasco.platform_device(), addr, sizeof(val), &val,
                           PLATFORM_CTL_FLAGS_NONE);
    } while (c == ERR);
    clear();
    return ERR;
  }

  int poke_and_wait() {
    char tmp[255];
    platform_ctl_addr_t addr{0x43c0000c};
    uint32_t val{0}, job{0};
    int c;
    clear();
    nocbreak();
    timeout(-1);
    echo();
    attron(A_REVERSE);
    mvprintw(rows / 2, (cols - 25) / 2, "Address:  ");
    attroff(A_REVERSE);
    getstr(tmp);
    addr = strtoul(tmp, NULL, 0);
    mvprintw(rows / 2, (cols - 25) / 2 + 10, "0x%08x", addr);
    attron(A_REVERSE);
    mvprintw(rows / 2 + 1, (cols - 25) / 2, "Value:    ");
    attroff(A_REVERSE);
    getstr(tmp);
    val = strtoul(tmp, NULL, 0);
    mvprintw(rows / 2 + 1, (cols - 25) / 2 + 10, "0x%08x", val);

    attron(A_REVERSE);
    mvprintw(rows / 2 + 2, (cols - 25) / 2, "Job# :    ");
    attroff(A_REVERSE);
    getstr(tmp);
    job = strtoul(tmp, NULL, 0);
    mvprintw(rows / 2 + 2, (cols - 25) / 2 + 10, "  %8u", job);

    attron(A_REVERSE);
    mvprintw(rows / 2 + 3, (cols - 25) / 2, "OK to poke (y/n)?");
    cbreak();
    timeout(0);
    noecho();
    do {
      c = getch();
      /*char chr = static_cast<char>(c);
      // FIXME reimplement with PAPI 1.5?
      if (chr == 'y')
        platform_write_ctl_and_wait(tapasco.platform_device(), addr,
      sizeof(val), &val, job, PLATFORM_CTL_FLAGS_NONE);*/
    } while (c == ERR);
    clear();
    return ERR;
  }

  int check_bitstream() {
    uint32_t cnt{0};
    while (cnt > 0) {
      platform_component_t isr_addr;
      platform_ctl_addr_t intc;
      switch (cnt) {
      case 4:
        isr_addr = PLATFORM_COMPONENT_INTC3;
        break;
      case 3:
        isr_addr = PLATFORM_COMPONENT_INTC2;
        break;
      case 2:
        isr_addr = PLATFORM_COMPONENT_INTC1;
        break;
      case 1:
        isr_addr = PLATFORM_COMPONENT_INTC0;
        break;
      default:
        return cnt * -10;
      }
      platform_address_get_component_base(tapasco.platform_device(), isr_addr,
                                          &intc);
      cerr << intc << endl;
      intc_addr.push_back(intc);
      --cnt;
    }
    for (int s = 0; s < 128; ++s) {
      uint32_t id = tapasco.platform_device()->info.composition.kernel[s];

      if (id) {
        struct slot_t *sp = new struct slot_t;
        sp->slot_id = s;
        sp->id = id;
        sp->base_addr = tapasco.platform_device()->info.base.arch[s];
        slots.push_back(sp);
        ++cnt;
      }
    }
    return cnt > 0 ? 0 : -3;
  }

  vector<slot_t *> slots;
  vector<platform_ctl_addr_t> intc_addr;
  uint32_t intc_isr[4];
  Tapasco &tapasco;
};

#endif /* MONITOR_SCREEN_HPP__*/
/* vim: set foldmarker=@{,@} foldlevel=0 foldmethod=marker : */
