Set-Location $PSScriptRoot
$h = 'user240165@IP_DEL_VPS'
$d = 'C:\Users\jesus\Desktop\Practica_Manual_240165\evidencias'
New-Item -ItemType Directory -Force $d | Out-Null
scp 05_conteo_registros.sh 06_postgres_docker.sh 00b_mysql_docker.sh ($h + ':/home/user240165/scripts/')
ssh $h 'bash ~/scripts/05_conteo_registros.sh'
scp ($h + ':/home/user240165/conteo_tablas.tsv') ($h + ':/home/user240165/evidencias_ejercicios.log') $d
