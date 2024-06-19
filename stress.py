import subprocess
import time,sys,re,os
import re

sendpassed='''curl -X POST -H "Content-Type: application/json" -d "{\"key\":\"$(cat /sys/class/net/eth0/address)-passed\"}" http://192.168.5.26:5000/data'''
sendtemps='''curl -X POST -H "Content-Type: application/json" -d "{\"key\":\"$(sensors)-$(cat /sys/class/net/eth0/address)\"}" http://192.168.5.26:5000/data'''


def parse_float(s):
    match = re.search(r'\d+\.\d+', s)
    if match:
        return float(match.group())
    else:
        return None

# Function to get computer serial number
def get_serial_number():
    command = "sudo dmidecode -s system-serial-number"
    serial_number = subprocess.check_output(command, shell=True).decode().strip()
    return serial_number

# Function to stress CPU, memory, and HDD
def start_stress():
    # Adjust the stress parameters as needed
    return subprocess.Popen(["stress", "--cpu", "4", "--io", "4","--timeout", sys.argv[1] ])

# Function to record temperatures and CPU usage
def record_temperatures_and_usage(stress_process, serial_number):
    final_record = ""
    while stress_process.poll() is None:  # Checks if stress process is still running
        # Retrieve temperatures for Core 0 and Core 1
        temp_core0 = subprocess.getoutput("sensors | grep 'Core 0:' | awk '{print $3}'")
        temp_core1 = subprocess.getoutput("sensors | grep 'Core 1:' | awk '{print $3}'")
        
        # Get current CPU usage
        cpu_usage = subprocess.getoutput("top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}'")
        
        current_time = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
        if parse_float(temp_core0)>85 or parse_float(temp_core1)>85:
                print('Temperatures are higher than expected, I will try to terminate the test now...') 
                os.popen('sudo killall stress')
                os.popen('sudo killall python') 
                exit()
        # Color the temperatures red
        red_temp_core0 = f"\033[91m{temp_core0}\033[0m"
        red_temp_core1 = f"\033[91m{temp_core1}\033[0m"
        final_record = f"{current_time} | CPU Usage: {cpu_usage}% | Core 0 Temp: {red_temp_core0} | Core 1 Temp: {red_temp_core1}"
        print(final_record)
        time.sleep(1)
        # Finished Successfully 
    os.system(sendpassed)
    os.system(sendtemps)

    
    # Write final record to log file
    log_filename = f"{serial_number}_SUCCESS.log"
    with open(log_filename, 'w') as log_file:
        log_file.write(final_record)
    
    print("Stress test completed. Exiting...")

if __name__ == "__main__":
    serial_number = get_serial_number()
    print(f"Starting stress test on system with serial number: {serial_number}")
    stress_process = start_stress()
    record_temperatures_and_usage(stress_process, serial_number)

