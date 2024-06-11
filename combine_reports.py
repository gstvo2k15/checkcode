import os

# Directorio de los informes
reports_dir = './reports'

# Nombres de los archivos de informes individuales
report_files = [
    'bandit_report.html',
    'pylint_report.html',
    'flake8_report/index.html',
    'shellcheck_report.html',
    'shfmt_report.html',
    'checkbashisms_report.html'
]

# Nombre del archivo de informe global
global_report_file = os.path.join(reports_dir, 'global_report.html')

# Comenzar el archivo de informe global
with open(global_report_file, 'w') as global_report:
    global_report.write('<html><head><title>Global Code Analysis Report</title></head><body>')
    global_report.write('<h1>Global Code Analysis Report</h1>')

    for report_file in report_files:
        report_path = os.path.join(reports_dir, report_file)
        if os.path.exists(report_path):
            with open(report_path, 'r') as report:
                global_report.write('<h2>{}</h2>'.format(report_file))
                global_report.write(report.read())
        else:
            global_report.write('<h2>{}</h2>'.format(report_file))
            global_report.write('<p>Report not found.</p>')

    global_report.write('</body></html>')