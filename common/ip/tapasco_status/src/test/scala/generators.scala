package de.tu_darmstadt.cs.esa.tapasco.tapasco_status
import  org.scalacheck._

package object generators {
  implicit val genSlotId: Gen[SlotId] = Gen.choose(0, NUM_SLOTS - 1) map (SlotId.apply _)
  implicit val genKernelId: Gen[KernelId] = Gen.posNum[Int] retryUntil (_ > 0) map (KernelId.apply _)
  implicit val genSize: Gen[Size] = Gen.choose(0, 10) map (i => Size(1 << i))

  val genYear: Gen[Int] = Gen.posNum[Int]
  val genRelease: Gen[Int] = Gen.posNum[Int] retryUntil (_ > 0)

  implicit val genTapascoVersion: Gen[Versions.Tapasco] = for {
    y <- genYear
    r <- genRelease
  } yield Versions.Tapasco(y, r)

  implicit val genVivadoVersion: Gen[Versions.Vivado] = for {
    y <- genYear
    r <- genRelease
  } yield Versions.Vivado(y, r)

  val genTimestamp: Gen[Int] = Gen.posNum[Int]

  implicit val genVersion: Gen[Versions.Version] = Gen.oneOf(genTapascoVersion, genVivadoVersion)

  implicit val genVersions: Gen[Versions] = for {
    tv <- genTapascoVersion
    vv <- genVivadoVersion
  } yield Versions(tapasco = tv, vivado = vv)

  implicit val genHostFreq: Gen[Clocks.HostFreq] = Gen.choose(1, 800) map (mhz => Clocks.HostFreq(mhz * 1000000))
  implicit val genDesignFreq: Gen[Clocks.DesignFreq] = Gen.choose(1, 800) map (mhz => Clocks.DesignFreq(mhz * 1000000))
  implicit val genMemFreq: Gen[Clocks.MemFreq] = Gen.choose(1, 800) map (mhz => Clocks.MemFreq(mhz * 1000000))

  implicit val genFreq: Gen[Clocks.Frequency] = Gen.oneOf(genHostFreq, genDesignFreq, genMemFreq)

  implicit val genClocks: Gen[Clocks] = for {
    h <- genHostFreq
    d <- genDesignFreq
    m <- genMemFreq
  } yield Clocks(host = h, design = d, memory = m)

  implicit def genKernel(slotId: Option[SlotId] = None): Gen[Slot.Kernel] = for {
    s <- genSlotId
    k <- genKernelId
  } yield Slot.Kernel(slotId getOrElse s, k)

  implicit def genMemory(slotId: Option[SlotId] = None): Gen[Slot.Memory] = for {
    s <- genSlotId
    k <- genSize
  } yield Slot.Memory(slotId getOrElse s, k)

  implicit def genSlot(slotId: Option[SlotId] = None): Gen[Slot] = Gen.oneOf(genKernel(slotId),
                                                                             genMemory(slotId))

  val genInterruptControllers: Gen[Int] = Gen.choose(1, 4)

  val genConfig: Gen[Seq[Slot]] = for {
    n <- Gen.choose(1, NUM_SLOTS - 1)
    slots <- Gen.pick(n, Gen.lzy(genSlot(Some(0))), Gen.lzy(genSlot(Some(1))), 2 until NUM_SLOTS map (s => Gen.lzy(genSlot(Some(s)))):_*)
  } yield slots

  implicit val genStatus: Gen[Status] = for {
    config <- genConfig
    timestamp <- genTimestamp
    interruptControllers <- genInterruptControllers
    versions <- genVersions
    clocks <- genClocks
  } yield Status(config, timestamp, interruptControllers, versions, clocks)
}
