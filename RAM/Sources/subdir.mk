################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.local

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS_QUOTED += \
"../Sources/__start_e6500_32bit_crt0.c" \
"../Sources/interrupt.c" \
"../Sources/main.c" \
"../Sources/smp_target.c" \

ASM_SRCS += \
../Sources/pa_exception.asm \

C_SRCS += \
../Sources/__start_e6500_32bit_crt0.c \
../Sources/interrupt.c \
../Sources/main.c \
../Sources/smp_target.c \

ASM_SRCS_QUOTED += \
"../Sources/pa_exception.asm" \

OBJS += \
./Sources/__start_e6500_32bit_crt0.o \
./Sources/interrupt.o \
./Sources/main.o \
./Sources/pa_exception.o \
./Sources/smp_target.o \

C_DEPS += \
./Sources/__start_e6500_32bit_crt0.d \
./Sources/interrupt.d \
./Sources/main.d \
./Sources/smp_target.d \

OBJS_QUOTED += \
"./Sources/__start_e6500_32bit_crt0.o" \
"./Sources/interrupt.o" \
"./Sources/main.o" \
"./Sources/pa_exception.o" \
"./Sources/smp_target.o" \

OBJS_OS_FORMAT += \
./Sources/__start_e6500_32bit_crt0.o \
./Sources/interrupt.o \
./Sources/main.o \
./Sources/pa_exception.o \
./Sources/smp_target.o \

C_DEPS_QUOTED += \
"./Sources/__start_e6500_32bit_crt0.d" \
"./Sources/interrupt.d" \
"./Sources/main.d" \
"./Sources/smp_target.d" \


# Each subdirectory must supply rules for building sources it contributes
Sources/__start_e6500_32bit_crt0.o: ../Sources/__start_e6500_32bit_crt0.c
	@echo 'Building file: $<'
	@echo 'Executing target #1 $<'
	@echo 'Invoking: PowerPC AEABI e6500 C Compiler'
	"$(PAGccAeabiE6500DirEnv)/powerpc-aeabi-gcc" "$<" @"Sources/__start_e6500_32bit_crt0.args" -MMD -MP -MF"$(@:%.o=%.d)" -o"Sources/__start_e6500_32bit_crt0.o"
	@echo 'Finished building: $<'
	@echo ' '

Sources/interrupt.o: ../Sources/interrupt.c
	@echo 'Building file: $<'
	@echo 'Executing target #2 $<'
	@echo 'Invoking: PowerPC AEABI e6500 C Compiler'
	"$(PAGccAeabiE6500DirEnv)/powerpc-aeabi-gcc" "$<" @"Sources/interrupt.args" -MMD -MP -MF"$(@:%.o=%.d)" -o"Sources/interrupt.o"
	@echo 'Finished building: $<'
	@echo ' '

Sources/main.o: ../Sources/main.c
	@echo 'Building file: $<'
	@echo 'Executing target #3 $<'
	@echo 'Invoking: PowerPC AEABI e6500 C Compiler'
	"$(PAGccAeabiE6500DirEnv)/powerpc-aeabi-gcc" "$<" @"Sources/main.args" -MMD -MP -MF"$(@:%.o=%.d)" -o"Sources/main.o"
	@echo 'Finished building: $<'
	@echo ' '

Sources/%.o: ../Sources/%.asm
	@echo 'Building file: $<'
	@echo 'Executing target #4 $<'
	@echo 'Invoking: PowerPC AEABI e6500 Assembler'
	"$(PAGccAeabiE6500DirEnv)/powerpc-aeabi-as" "$<" -g -a32 -me6500 -o"$@"
	@echo 'Finished building: $<'
	@echo ' '

Sources/smp_target.o: ../Sources/smp_target.c
	@echo 'Building file: $<'
	@echo 'Executing target #5 $<'
	@echo 'Invoking: PowerPC AEABI e6500 C Compiler'
	"$(PAGccAeabiE6500DirEnv)/powerpc-aeabi-gcc" "$<" @"Sources/smp_target.args" -MMD -MP -MF"$(@:%.o=%.d)" -o"Sources/smp_target.o"
	@echo 'Finished building: $<'
	@echo ' '


