import subprocess
from prometheus_client import start_http_server, Gauge
import time

# Iniciar el servidor HTTP de Prometheus
start_http_server(8084)

# Crear instancias de Gauge para el uso de CPU, memoria y red del proceso
cpu_usage = Gauge('process_cpu_usage', 'CPU usage of a process')
memory_usage = Gauge('process_memory_usage', 'Memory usage of a process')
network_usage = Gauge('process_network_usage', 'Network usage of a process')

# Crear una instancia de Gauge para indicar si el proceso está en ejecución o no
process_running = Gauge('process_running', 'Process running', ['process_name'])

while True:
    # Ejecutar el comando `ps aux` y obtener la salida
    ps_output = subprocess.check_output(['ps', 'aux']).decode()

    # Buscar la línea que contiene el proceso deseado
    for line in ps_output.splitlines():
        if "/univiewer" in line:
            # Dividir la línea por espacios y obtener los valores de CPU, memoria y red
            items = line.split()
            cpu_percent = float(items[2])
            memory_percent = float(items[3])
            memory_percent = memory_percent / 1024
            network_bytes = float(items[4])
            network_bytes = network_bytes / 1024 / 1024
            # Establecer los valores en las métricas de Prometheus
            cpu_usage.set(cpu_percent)
            memory_usage.set(memory_percent)
            network_usage.set(network_bytes)
            # Establecer el valor de la métrica process_running en 1 si el proceso está en ejecución
            process_running.labels(process_name='/univiewer').set(1)
            break
    else:
        # Si no se encontró el proceso, establecer el valor de la métrica process_running en 0
        process_running.labels(process_name='/univiewer').set(0)

    # Esperar 5 segundos antes de ejecutar `ps aux` nuevamente
    time.sleep(5)

