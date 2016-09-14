package chisel.axiutils

/**
 * Configuration parameters for AXI-MM interfaces (slave, master).
 * @param addrWidth Width of address line(s) in bits.
 * @param dataWidth Width of data line(s) in bits.
 * @param idWidth Width of id line(s) in bits.
 **/
case class AxiConfiguration(addrWidth: Int, dataWidth: Int, idWidth: Int) {
  require (addrWidth > 0 && addrWidth <= 128, "addrWidth (%d) must be 0 < addrWidth <= 128 bits".format(addrWidth))
  require (dataWidth > 0 && dataWidth <= 128, "dataWidth (%d) must be 0 < dataWidth <= 128 bits".format(dataWidth))
  require (idWidth > 0 && idWidth <= 128, "idWidth (%d) must be 0 < idWidth <= 128 bits".format(idWidth))
}
