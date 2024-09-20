################################################################################
# Automatically-generated file. Do not edit!
################################################################################

#Progress monitor hint: 5
first : all
-include ../makefile.init

# 如果存在，此文件包含在生成文件和.args文件中使用的环境变量。
-include makefile.local

RM := "$(GNU_Make_Install_DirEnv)/rm" -f

# All of the sources participating in the build are defined here
-include sources.mk
-include subdir.mk
-include Sources/subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
ifneq ($(strip $(SX_DEPS)),)
-include $(SX_DEPS)
endif
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
endif

-include ../makefile.defs

# Add inputs and outputs from these tool invocations to the build variables 
EXECUTABLES += \
T4240QDS.elf \

EXECUTABLES_QUOTED += \
"T4240QDS.elf" \

EXECUTABLES_OS_FORMAT += \
T4240QDS.elf \


# All Target
all: warning-messages explicit-dependencies T4240QDS.elf

# Tool invocations
T4240QDS.elf: $(OBJS) $(USER_OBJS) ../LCF/T4240QDS_gcc-aeabi_SMP.lcf
	@echo 'Building target: $@'
	@echo 'Executing target #6 $@'
	@echo 'Invoking: PowerPC AEABI e6500 C Linker'
	"$(PAGccAeabiE6500DirEnv)/powerpc-aeabi-gcc"  $(USER_OBJS_QUOTED)  @"T4240QDS.args" -o"T4240QDS.elf"
	@echo 'Finished building target: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) "./*/*.o"  $(SX_DEPS_QUOTED) $(EXECUTABLES_QUOTED) $(S_UPPER_DEPS_QUOTED) "./*/*.d"  $(ProjDirPath)/RAM/T4240QDS.elf
	-@echo ' '

.PHONY: all clean dependents explicit-dependencies warning-messages
.SECONDARY:

-include ../makefile.targets

explicit-dependencies: ../LCF/T4240QDS_gcc-aeabi_SMP.lcf 

warning-messages: 

