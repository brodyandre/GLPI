- GLPI
Instalando o GLPI no Ubuntu 22.04.4 LTS

-----------------------------------------------------------------------------------------------------------------------------------------

Este repositório contém um guia passo a passo para instalar e configurar o GLPI (Gestão Livre de Parque de Informática) em um servidor Ubuntu 22.04 LTS. O processo inclui a configuração de um ambiente LAMP (Apache, MariaDB e PHP) e ajustes de segurança recomendados.

-----------------------------------------------------------------------------------------------------------------------------------------
Pré-Requisitos

Servidor Ubuntu 22.04.04 LTS
Acesso root ou sudo
Conexão à internet
Etapas de Instalação
----------------------------------------------------------------------------------------------------------------------------------------
Atualização do sistema: Garantir que todos os pacotes estão atualizados.
Configuração do servidor: Instalação do Apache, MariaDB e PHP com extensões necessárias.
Configuração do banco de dados: Criação do banco de dados e permissões para o GLPI.
Download e instalação do GLPI: Baixar, descompactar e configurar permissões do GLPI.
Configuração do Apache: Criar e habilitar o VirtualHost para o GLPI.
Ajustes de segurança: Mover diretórios sensíveis e ajustar permissões.
Primeiros Passos
----------------------------------------------------------------------------------------------------------------------------------------

Após a instalação, acesse o GLPI via navegador para finalizar a configuração e criar um usuário administrador.

----------------------------------------------------------------------------------------------------------------------------------------

Segurança

Excluir usuários padrão.
Configurar corretamente os diretórios de configuração e dados.
