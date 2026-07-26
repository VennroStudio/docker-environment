<?php
$i = 0;

$i++;
$cfg['Servers'][$i]['verbose'] = 'Mariadb 10.6';
$cfg['Servers'][$i]['host'] = 'mariadb-container';
$cfg['Servers'][$i]['port'] = '3306';
$cfg['Servers'][$i]['auth_type'] = 'config';  # Автологин
$cfg['Servers'][$i]['user'] = 'root';
$cfg['Servers'][$i]['password'] = 'root';
