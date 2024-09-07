#!/bin/bash

####################################################################
# brodyandre - Data Engineer
# Atividade: INSTALAÇÃO GLPI
# @Responsável: landresouza36@gmail.com
# @Data: 07/09/2024 Versão: 1.1 update glpi version
# @Data: 05/09/2024 Versão: 1.0 initial version
# @Homologado: Ubuntu 22.04.4 LTS
####################################################################

####################################################################
# 1. Pré-Requisitos
####################################################################
# 1.1. Servidor Ubuntu 22.04 LTS Instalado
# 1.2. Acesso a internet para download e instalação de pacotes
# 1.3. Acesso de root ao servidor

####################################################################
# 2. Instalação
####################################################################
echo "Atualizando pacotes..."
sudo apt update && sudo apt dist-upgrade -y || { echo "Falha ao atualizar pacotes"; exit 1; }

echo "Reconfigurando timezone..."
sudo dpkg-reconfigure tzdata || { echo "Falha ao reconfigurar timezone"; exit 1; }

echo "Instalando Apache, PHP e MySQL..."
sudo apt install -y \
	apache2 \
	mariadb-server \
	mariadb-client \
	libapache2-mod-php \
	php-dom \
	php-fileinfo   \
	php-json \
	php-simplexml \
	php-xmlreader \
	php-xmlwriter \
	php-curl \
	php-gd \
	php-intl \
	php-mysqli   \
	php-bz2  \
	php-zip \
	php-exif \
	php-ldap  \
	php-opcache \
	php-mbstring || { echo "Falha ao instalar pacotes"; exit 1; }

echo "Criando banco de dados do GLPI..."
sudo mysql -e "CREATE DATABASE glpi"
sudo mysql -e "GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'localhost' IDENTIFIED BY 'P4ssw0rd'"
sudo mysql -e "GRANT SELECT ON mysql.time_zone_name TO 'glpi'@'localhost'"
sudo mysql -e "FLUSH PRIVILEGES" || { echo "Falha ao criar banco de dados"; exit 1; }

echo "Carregando timezones no MySQL..."
mysql_tzinfo_to_sql /usr/share/zoneinfo | sudo mysql -u root mysql || { echo "Falha ao carregar timezones"; exit 1; }

echo "Desabilitando o site padrão do Apache..."
sudo a2dissite 000-default.conf || { echo "Falha ao desabilitar site padrão"; exit 1; }

echo "Habilitando configuração do PHP..."
sudo sed -i 's/^session.cookie_httponly =/session.cookie_httponly = on/' /etc/php/8.1/apache2/php.ini && \
	sudo sed -i 's/^;date.timezone =/date.timezone = America\/Sao_Paulo/' /etc/php/8.1/apache2/php.ini || { echo "Falha ao modificar php.ini"; exit 1; }

echo "Criando o VirtualHost do GLPI..."
cat << EOF | sudo tee /etc/apache2/sites-available/glpi.conf
<VirtualHost *:80>
	ServerName glpi.ninjapfsense.com.br
	DocumentRoot /var/www/glpi/public
	<Directory /var/www/glpi/public>
		Require all granted
		RewriteEngine On
		# Redirect all requests to GLPI router, unless file exists.
		RewriteCond %{REQUEST_FILENAME} !-f
		RewriteRule ^(.*)$ index.php [QSA,L]
	</Directory>
</VirtualHost>
EOF

echo "Habilitando o VirtualHost..."
sudo a2ensite glpi.conf || { echo "Falha ao habilitar VirtualHost"; exit 1; }

echo "Habilitando módulos do Apache necessários..."
sudo a2enmod rewrite || { echo "Falha ao habilitar módulos do Apache"; exit 1; }

echo "Reiniciando o Apache..."
sudo systemctl restart apache2 || { echo "Falha ao reiniciar Apache"; exit 1; }

echo "Fazendo download do GLPI..."
wget -q https://github.com/glpi-project/glpi/releases/download/10.0.9/glpi-10.0.9.tgz || { echo "Falha ao fazer download do GLPI"; exit 1; }

echo "Descompactando o GLPI..."
tar -zxf glpi-10.0.9.tgz || { echo "Falha ao descompactar o GLPI"; exit 1; }

echo "Movendo a pasta do GLPI para /var/www/glpi..."
sudo mv glpi /var/www/glpi || { echo "Falha ao mover a pasta do GLPI"; exit 1; }

echo "Configurando permissões na pasta /var/www/glpi..."
sudo chown -R www-data:www-data /var/www/glpi/ || { echo "Falha ao configurar permissões"; exit 1; }

echo "Finalizando setup do GLPI pela linha de comando..."
sudo php /var/www/glpi/bin/console db:install \
	--default-language=pt_BR \
	--db-host=localhost \
	--db-port=3306 \
	--db-name=glpi \
	--db-user=glpi \
	--db-password=P4ssw0rd -n -vvv || { echo "Falha ao finalizar setup"; exit 1; }

####################################################################
# 3. Ajustes de Segurança
####################################################################
echo "Removendo o arquivo de instalação..."
sudo rm /var/www/glpi/install/install.php || { echo "Falha ao remover arquivo de instalação"; exit 1; }

echo "Movendo pastas do GLPI de forma segura..."
sudo mv /var/www/glpi/files /var/lib/glpi || { echo "Falha ao mover pastas"; exit 1; }
sudo mv /var/www/glpi/config /etc/glpi || { echo "Falha ao mover pastas"; exit 1; }
sudo mkdir /var/log/glpi && sudo chown -R www-data:www-data /var/log/glpi || { echo "Falha ao configurar diretórios de logs"; exit 1; }

echo "Configurando arquivos de definição do GLPI..."
cat << EOF | sudo tee /var/www/glpi/inc/downstream.php
<?php
define('GLPI_CONFIG_DIR', '/etc/glpi/');
if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
   require_once GLPI_CONFIG_DIR . '/local_define.php';
}
EOF

cat << EOF | sudo tee /etc/glpi/local_define.php
<?php
define('GLPI_VAR_DIR', '/var/lib/glpi');
define('GLPI_LOG_DIR', '/var/log/glpi');
EOF

####################################################################
# 4. Primeiros Passos
####################################################################
echo "Configuração inicial concluída. Acesse o GLPI via navegador para finalizar a configuração."
echo "Crie um novo usuário com perfil super-admin."
echo "Remova os usuários glpi, normal, post-only, tech."
echo "Configure a URL de acesso ao sistema em: Configurar -> Geral -> Configuração Geral -> URL da aplicação."
