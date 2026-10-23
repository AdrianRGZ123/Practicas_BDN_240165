#!/bin/bash
# Uso (en el VPS): bash ~/scripts/05_conteo_registros.sh  -> genera ~/conteo_tablas.tsv (tabla<TAB>registros)
M="docker exec -i mysql40166 mysql -uroot -pRoot240165 -N -B db_test"
OUT=~/conteo_tablas.tsv; : > $OUT
for t in $($M -e "SELECT table_name FROM information_schema.tables WHERE table_schema='db_test' AND table_type='BASE TABLE' ORDER BY table_name" 2>/dev/null); do
  n=$($M -e "SELECT COUNT(*) FROM \`$t\`" 2>/dev/null); printf "%s\t%s\n" "$t" "$n" >> $OUT
done
cat $OUT
