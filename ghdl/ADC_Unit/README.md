Currently, the top level module `adc_unit` contains 5 submodules. 
## Registers:
The `adc_registers` module is used with a register bus to configure the `adc_unit` from the Linux driver. The addresses of this register bus are 16 bits,
with all the registers in this module having the first 4 bits `0xD`. The enable register, at `0xD000` should have its last two bits written to 1 to enable the BRAM and ADC. The read only registers of this module,
which check on the internals of `adc_unit`, all have addresses with the first 8 bits `0xD1`. These registers are described as follows: 
* Look register, address `0xD100`, is updated with the registered ADC data every clock cycle
* Rising count, address `0xD104`, counts the number of rising edge triggers
* Falling count, address `0xD108`, counts the number of falling edge triggers
* Status register, address `0xD10C`, the last 3 hexadecimal digits read the 11 bits that is the last adresss written to and the fourth hexadecimal digit is the write enable used during the write to that address, note that this
address is only 11 bits because the BRAM addresses are 13 bits but the last 2 bits must be 0
* Last data written, address `0xD110`, the last 32 bit word of data written to the BRAM

Besides the enable register, all writable registers have addresses with the first 8 bits `0xD2`. These registers are described as follows:
* ADC_Config, address `0xD200`, the most signficant 16 bits are the wait time for the test pattern, that is if the first 16 bits represent an integer $n$, the test pattern is incremented every $n+1$ clock cycles.
 The least significant 13 bits represent the step size we are incrementing in the test pattern output, these 13 bits act as a signed type so the step size can be negative. The middle 3 bits (15-13) represent the options for the mux,
if these are 0, then the `adc_input_mux` module passes through the ADC input data, if this is set to 1 then the output data of the `adc_input mux` are test patterns defined by this register and the ADC_Test_Range register.
Every other value for these three bits make this data all zeros.
* ADC_Test_Range, address `0xD204`, the last 13 bits of the most significant 16 bits are the upper bound of the test patter, the last 13 bits of the least significant 16 bits are the lower bound of the test pattern for the `adc_input_mux`. These values are offset from the ADC data by a value of `0x800`, that is, any lower bound of below this would be considered overflow and would start at `0x1000` until it has surpassed `0x800`. If you want a bound at an ADC value of `0x900`, the corresponding input should be `0x1100`.
* ADC_Trig_Config, address `0xD208`, bits 27-16 are the 12 bit threshold for the trigger condition, bits 11-0 are the 12 bit swing value for the trigger condition. If the upper or lower bounds resulting from this exceed
  the allowed range, they are set to the maximum or minimum possible values, respectively.
* ADC_Valid_Config, address `0xD20C`, mostly unused in this version, can be set to all 1's to stop writing to the BRAM.
* BRAM_Config, the least signficant 11 bits are the number of addresses to write to while using the bram as a circular buffer (in previous version this was the 13 bit number corresponding the the maximum address we would write to,
  but for simplicity, we have removed the last 2 bits), if this is set to 0, the entire circular buffer is used. The next hexadecimal digit, bits 15-12, represent the amount of bit packing. A value of 0 will not output anything to the BRAM, a value of 1 will store the data at the least significant
  13 bits of the address given with the remaining bits set to 0, a value of 2 will store 13 bits of data in both the upper and lower 16 bits of the address, and a value of 3 will store the most significant 8 bits of data in one of the
  four byters at the given address. For the bit packing modes, the write enable determines where in the BRAM addresss we write our data.

## Modules:
* The `adc_registers` module lets us write registers from the linux driver.
* The `adc_input_mux` module inputs ADC data, registers it, and send it to the look register. This module then outputs intermediate data that is used by other modules. This intermediate data is either the ADC data or the test patterns.
* The `adc_trigger` module detects rising and falling edges of the intermediate data. It outpus rising and falling edge pulses when a rising or falling edge is detected, respectively.
* The `adc_bram` module writes the intermediate data from `adc_input_mux` to the BRAM in one of many ways, specified in the registers section.
* The `adc_valid` module counts the number of rising and falling edge pulses as supplied by the `adc_trigger` module. It is also responsible for supplying the `adc_bram` module with a valid signal that specifies when the module should
 write the data to the BRAM. Currently, this signal is high, meaning the intermediate data is always written to the BRAM, unless the ADC_Valid_Config register is all ones.


## Edge Cases
* The trigger conditions are inclusive, meaning that if the threshold and swing have values of `0x800` and `0x080` then a rising edge would be found if the data underwent a transition from `0x780` to `0x880`. If the swing is zero, then data at the threshold value is considered lower than the lower bound. That is a theshold and swing value of `0x800` and a `0x000` would trigger a rising edge on the data transition of `0x800` to `0x801`, but would not trigger a falling edge from `0x800` to `0x7FF`.
* In `adc_input_mux` the test pattern data will reset to the higher bound when the step is at or above the 13 bit value of `0x1000` and the lower bound when it is less that this. The data is reset if one clock cycle of data is out of this range. However, if the step is large enough to transition the data from below the higher bound, to above the lower bound (as the carry bit will be lost) then the data will not be reset.
