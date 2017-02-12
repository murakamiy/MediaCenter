import bluetooth

f = open("/home/mc/.bluetooth_addr", "r")
addr = f.read()
f.close()

services = bluetooth.find_service(address=addr.rstrip())
