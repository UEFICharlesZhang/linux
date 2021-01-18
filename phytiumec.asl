        Device (LPC1)
        {
            Name (_HID, "LPC0001")  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                Memory32Fixed (ReadWrite,
                    0x20000000,         // Address Base
                    0x07FFFFFD,         // Address Length
                    )
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, )
                {
                    0x00000025,
                }
            })
        }

        Device (PWRB)
        {
            Name (_HID, "PNP0C0C" /* Power Button Device */)  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }
        }

        Device (EC0)
        {
            Name (_HID, EisaId ("PNP0C09"))  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                IO(Decode16, 0x62, 0x62, 0, 1)
                IO(Decode16, 0x66, 0x66, 0, 1)

                /* For HW-Reduced ACPI Platforms, include a GPIO Interrupt Connection resource */
                GpioInt (Edge, ActiveLow, ExclusiveAndWake, PullUp, 0x0000,
                        "\\_SB.GPI0", 0x00, ResourceConsumer, ,)
                {
                        0x07
                }

                Memory32Fixed (ReadWrite,
                        0x20000000,     // Address Base
                        0x00000100,     // Address Length
                )
            })

            OperationRegion (ERAM, EmbeddedControl, 0x0, 0x100)
            Field (ERAM, ByteAcc, NoLock, WriteAsZeros)
            {
                Offset  (0x21),
                RCPT,   8,              // Battery Remaining Capacity Percent
                Offset  (0x24),
                FCCL,   8,              // Battery Fullcharged Capacity
                FCCH,   8,
                RMCL,   8,              // Battery RemainingCapacity
                RMCH,   8,
                TMPL,   8,              // Battery Temperature
                TMPH,   8,
                VOLL,   8,              // Battery Voltage
                VOLH,   8,
                CURL,   8,              // Battery Current
                CURH,   8,
                AVRL,   8,              // Battery Average Current
                AVRH,   8,
                Offset  (0x38),
                DGCL,   8,              // Battery Design Capacity
                DGCH,   8,
                DGVL,   8,              // Battery Design Voltage
                DGVH,   8,
                BSTS,   8,              // Battery Status
                Offset  (0x3E),
                BSNL,   8,              // Battery Serial Number
                BSNH,   8,
                Offset  (0x46),
                LPOL,   1,              // Lid polarity control bit
                Offset  (0xB0),
                PPRS,   8               // Power Present
            }

            Method (_QB3, 0 , NotSerialized)
            {
                Notify (\_SB.EC0.BAT1, 0x80)
            }

            Method (_QB4, 0, NotSerialized)
            {
                Notify (\_SB.EC0.AC, 0x80)
            }

            Method (_QB5, 0, NotSerialized)
            {
                Notify (\_SB.PWRB, 0x80)
            }

            Method (_QD0, 0 , NotSerialized)
            {
                Notify (\_SB.EC0.LID0, 0x80)
            }

            Device (BAT1)
            {
                Name (_HID, "PNP0C0A")  // _HID: Hardware ID
                Name (_UID, Zero)  // _UID: Unique ID

                Name (B1ST, 0x1F)
                Method (_STA, 0, NotSerialized)
                {
                        Store (PPRS, Local1)
                        And (Local1, 0x02, Local2)
                        If (Local2)
                        {
                                Store (0x1F, B1ST)
                        }
                        Else
                        {
                                Store (0x0F, B1ST)
                        }

                        Return (B1ST)
                }

                Name (PBIX, Package (0x15)
                {
                        0x1,                    // Revision
                        0x00000001,             // Power Unit
                        0xFFFFFFFF,             // Design Capacity
                        0xFFFFFFFF,             // Last Full Charge Capacity
                        0x00000001,             // Battery Technology
                        0x32C8,                 // Design Voltage
                        0xFA,                   // Design Capacity of Warning
                        0x64,                   // Design Capacity of Low
                        0xFFFFFFFF,             // Cycle Count
                        50000,                  // Measurement Accuracy
                        0xFFFFFFFF,             // Max Sampling Time
                        0xFFFFFFFF,             // Min Sampling Time
                        0x03E8,                 // Max Averaging Interval
                        0x01F4,                 // Min Averaging Interval
                        0xFFFFFFFF,             // Battery Capacity Granularity 1
                        0xFFFFFFFF,             // Battery Capacity Granularity 2
                        "EC-BAT",               // Model Number
                        "kylin",                // Serial Number
                        "Lion",                 // Battery Type
                        "OEM",                  // OEM Information
                        0x00000000              // Battery Swapping Capability
                })

                Name (PBST, Package (0x04)
                {
                        0x0,                    // Battery State
                        0xFFFFFFFF,             // Battery Rate
                        0xFFFFFFFF,             // Battery Remaining Capacity
                        0xFFFFFFFF,             // Battery Present Voltage
                })

                Method (_BIX, 0, NotSerialized)
                {
                        UBIX ()

                        Return (PBIX)
                }

                Method (_BST, 0, NotSerialized)
                {
                        UBST ()

                        Return (PBST)
                }

                Method (UBIX, 0, NotSerialized)
                {
                        Store (DGCL, Local1)
                        Store (DGCH, Local2)
                        ShiftLeft (Local2, 0x8, Local2)
                        Or (Local2, Local1, Local2)
                        Store (Local2, Index (PBIX, 0x02))

                        Store (FCCL, Local1)
                        Store (FCCH, Local2)
                        ShiftLeft (Local2, 0x8, Local2)
                        Or (Local2, Local1, Local2)
                        Store (Local2, Index (PBIX, 0x03))
                }

                Method (UBST, 0, NotSerialized)
                {
                        Store (PPRS, Local1)
                        Store (BSTS, Local2)

                        And (Local1, 0x01, Local3)
                        And (Local1, 0x02, Local4)

                        If (Local4)
                        {
                                If (Local3)
                                {
                                        Store (0x02, Index (PBST, 0x00))
                                }
                                Else
                                {
                                        Store (0x01, Index (PBST, 0x00))
                                }
                        }
                        Else
                        {
                                Store (BSTS, Index (PBST, 0x00))
                        }

                        Store (CURL, Local1)
                        Store (CURH, Local2)
                        ShiftLeft (Local2, 0x8, Local2)
                        Or (Local2, Local1, Local2)
                        Store (Local2, Index (PBST, 0x01))

                        Store (RMCL, Local1)
                        Store (RMCH, Local2)
                        ShiftLeft (Local2, 0x8, Local2)
                        Or (Local2, Local1, Local2)
                        Store (Local2, Index (PBST, 0x02))

                        Store (VOLL, Local1)
                        Store (VOLH, Local2)
                        ShiftLeft (Local2, 0x8, Local2)
                        Or (Local2, Local1, Local2)
                        Store (Local2, Index (PBST, 0x03))
                }
	}

            Device (AC)
            {
                Name (_HID, "ACPI0003") // _HID: Hardware ID
                Name (_UID, 0x0)

                Method (_STA, 0, NotSerialized)
                {
                        Return (0x0F)
                }

                Method (_PSR, 0, NotSerialized) // _PSR: Power Source
                {
                        Store (PPRS, Local1)
                        And (Local1, 0x01, Local1)

                        If (Local1)
                        {
                                Return (0x01)
                        }
                        Else
                        {
                                Return (0x00)
                        }
                }
            }

            Device (LID0)
            {
                Name (_HID, EISAID("PNP0C0D"))  // _HID: Hardware ID
                Name (_UID, Zero)  // _UID: Unique ID
                Method (_LID)
                {
                        And (LPOL, 0x01, Local0)
                        Return (LNot (Local0))
                }
            }
Device(KBC) {
                Name(_HID, "KBCI8042")
                Name(_UID, 0)

                Name (_DSD, Package()
                {
                    ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
                    Package (0x02)
                    {
                        Package (0x02)
                        {
                            "i8042_command_reg",
                            0x64
                        },

                        Package (0x02)
                        {
                            "i8042_data_reg",
                            0x60
                        }
                    }
                })
    }//Device (KBC)
            Device (PWM0)
            {
                Name (_HID, "FTBL0001")  // _HID: Hardware ID
                Name (_UID, Zero)  // _UID: Unique ID
                Name (_DSD, Package (0x02)  // _DSD: Device-Specific Data
                {
                    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301") /* Device Properties for _DSD */, 
                    Package (0x02)
                    {
                        Package (0x02)
                        {
                            "index_display_brightness",
                            0x0E
                        },

                        Package (0x02)
                        {
                            "max_brightness",
                            0x64
                        }
                    }
                })
            }
	}
