.PHONY: help up down logs setup clean restart test validate

# Variables
COMPOSE := docker-compose
DB2_FED := db2_federated
DB2_REM := db2_remote

# Color output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

help: ## Mostrar esta ayuda
	@echo "$(GREEN)TASD-Federation - Docker Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Ejemplo:$(NC)"
	@echo "  make up"
	@echo "  make setup"
	@echo "  make logs"
	@echo ""

up: ## Iniciar contenedores en background
	@echo "$(GREEN)[*] Iniciando contenedores...$(NC)"
	$(COMPOSE) up -d
	@echo "$(GREEN)[✓] Contenedores iniciados$(NC)"
	@$(COMPOSE) ps

down: ## Detener contenedores (mantiene volúmenes)
	@echo "$(GREEN)[*] Deteniendo contenedores...$(NC)"
	$(COMPOSE) down
	@echo "$(GREEN)[✓] Contenedores detenidos$(NC)"

clean: ## Detener y eliminar volúmenes (CUIDADO: elimina datos)
	@echo "$(RED)[!] ADVERTENCIA: Esto eliminará todos los datos$(NC)"
	@echo "¿Continuar? [y/N] " && read ans && [ $${ans:-N} = y ]
	$(COMPOSE) down -v
	@echo "$(GREEN)[✓] Volúmenes eliminados$(NC)"

logs: ## Ver logs en tiempo real
	$(COMPOSE) logs -f

logs-fed: ## Ver logs del nodo federador
	$(COMPOSE) logs -f $(DB2_FED)

logs-rem: ## Ver logs del nodo remoto
	$(COMPOSE) logs -f $(DB2_REM)

setup: ## Ejecutar script de inicialización
	@echo "$(GREEN)[*] Ejecutando setup...$(NC)"
	@chmod +x setup.sh
	@./setup.sh

ps: ## Ver estado de contenedores
	$(COMPOSE) ps

restart: ## Reiniciar contenedores
	@echo "$(GREEN)[*] Reiniciando contenedores...$(NC)"
	$(COMPOSE) restart
	@echo "$(GREEN)[✓] Contenedores reiniciados$(NC)"

status: ## Ver estado del sistema
	@echo "$(GREEN)Estado de contenedores:$(NC)"
	@$(COMPOSE) ps
	@echo ""
	@echo "$(GREEN)Uso de recursos:$(NC)"
	@docker system df

validate: ## Validar docker-compose.yml
	@echo "$(GREEN)[*] Validando docker-compose.yml...$(NC)"
	@docker-compose config > /dev/null && echo "$(GREEN)[✓] Configuración válida$(NC)" || echo "$(RED)[✗] Configuración inválida$(NC)"

shell-fed: ## Acceder a bash del nodo federador
	docker exec -it $(DB2_FED) bash

shell-rem: ## Acceder a bash del nodo remoto
	docker exec -it $(DB2_REM) bash

sql-fed: ## Acceder a CLI de DB2 en nodo federador
	docker exec -it $(DB2_FED) bash -c "su - db2inst1 << 'EOF'\ndb2 connect to BASETASD\nexit\nEOF"

sql-rem: ## Acceder a CLI de DB2 en nodo remoto
	docker exec -it $(DB2_REM) bash -c "su - db2inst1 << 'EOF'\ndb2 connect to SAMPLE\nexit\nEOF"

query-fed: ## Ejecutar query de prueba en federador
	@echo "$(GREEN)Consultando nicknames federados...$(NC)"
	docker exec -i $(DB2_FED) bash -c "su - db2inst1 << 'EOF'\ndb2 connect to BASETASD\ndb2 'SELECT TABNAME, REMOTE_NAME FROM SYSCAT.NICKTAB'\ndb2 connect reset\nEOF"

query-rem: ## Ejecutar query de prueba en remoto
	@echo "$(GREEN)Consultando tablas remotas...$(NC)"
	docker exec -i $(DB2_REM) bash -c "su - db2inst1 << 'EOF'\ndb2 connect to SAMPLE\ndb2 'SELECT * FROM DB2INST1.DEPARTMENT'\ndb2 connect reset\nEOF"

test: ## Ejecutar pruebas de conectividad
	@echo "$(GREEN)[*] Probando conectividad...$(NC)"
	@echo "$(YELLOW)Ping de db2_federated a db2_remote:$(NC)"
	@docker exec $(DB2_FED) ping -c 3 $(DB2_REM) 2>/dev/null || echo "Ping completado"
	@echo ""
	@echo "$(YELLOW)Verificando estado de los contenedores:$(NC)"
	@$(COMPOSE) ps
	@echo ""
	@echo "$(GREEN)[✓] Pruebas completadas$(NC)"

backup-fed: ## Hacer backup del nodo federador
	@echo "$(GREEN)[*] Iniciando backup del nodo federador...$(NC)"
	docker exec -i $(DB2_FED) bash -c "su - db2inst1 -c 'db2 connect to BASETASD; db2 backup db BASETASD to /dev/stdout'" > basetasd_backup_$$(date +%Y%m%d_%H%M%S).bak
	@echo "$(GREEN)[✓] Backup completado$(NC)"

backup-rem: ## Hacer backup del nodo remoto
	@echo "$(GREEN)[*] Iniciando backup del nodo remoto...$(NC)"
	docker exec -i $(DB2_REM) bash -c "su - db2inst1 -c 'db2 connect to SAMPLE; db2 backup db SAMPLE to /dev/stdout'" > sample_backup_$$(date +%Y%m%d_%H%M%S).bak
	@echo "$(GREEN)[✓] Backup completado$(NC)"

clean-backups: ## Eliminar archivos de backup
	@echo "$(RED)[!] Eliminando backups...$(NC)"
	rm -f *_backup_*.bak
	@echo "$(GREEN)[✓] Backups eliminados$(NC)"

prune: ## Limpiar recursos de Docker (contenedores/imágenes no usadas)
	@echo "$(RED)[!] ADVERTENCIA: Esto eliminará recursos no usados$(NC)"
	docker system prune -f
	@echo "$(GREEN)[✓] Limpieza completada$(NC)"

version: ## Mostrar versiones
	@echo "$(GREEN)Versiones instaladas:$(NC)"
	@docker --version
	@docker-compose --version
	@db2 --version 2>/dev/null || echo "DB2 not installed locally"

info: ## Mostrar información del proyecto
	@echo "$(GREEN)TASD-Federation v1.0.0$(NC)"
	@echo "$(YELLOW)Nodo Federador:$(NC) db2_federated (BASETASD) - Puerto 50000"
	@echo "$(YELLOW)Nodo Remoto:$(NC) db2_remote (SAMPLE) - Puerto 50001"
	@echo "$(YELLOW)Network:$(NC) db2_network (bridge)"
	@echo ""
	@echo "$(GREEN)Archivos principales:$(NC)"
	@echo "  - docker-compose.yml"
	@echo "  - setup.sh / setup.bat"
	@echo "  - scripts/init_federation.sql"
	@echo "  - scripts/init_sample_db.sql"
	@echo "  - data/file_clientes2.txt"
	@echo ""
	@echo "$(GREEN)Ver más:$(NC) make help"

.DEFAULT_GOAL := help
