workspace "Smart Campus UniSenai" "Dossiê de Arquitetura Viva - Acesso biométrico e energização de laboratório (APS 3)" {

    model {
        usuario = person "Usuário" "Aluno, Professor, Técnico ou Visitante"
        gestao = person "Gestão do Campus" "ADMs que analisam consumo e alertas de desperdício"

        grade = softwareSystem "Grade Horária Acadêmica" "Fonte de verdade das aulas programadas" "Externo"
        iot = softwareSystem "Rede IoT de Atuadores" "Tomadas inteligentes, iluminação e ar-condicionado" "Externo"

        smartCampus = softwareSystem "Smart Campus UniSenai" "Controle de acesso biométrico integrado à gestão de energia" {
            terminal = container "Terminal Biométrico" "Captura biometria e controla a fechadura" "Raspberry Pi 4, Python 3.12, SDK biométrico"

            api = container "API de Acesso" "Decide acesso e abre/associa Sessão de Uso" "Python 3.12, FastAPI" {
                controlador = component "ControladorAcesso" "solicitarAcesso(SolicitacaoAcessoDTO): DecisaoAcessoDTO" "FastAPI router"
                identidade = component "ServicoIdentidade" "validarCredencial(CredencialDTO): IdentidadeDTO" "Python"
                permissao = component "ServicoPermissao" "verificarPermissao(ConsultaPermissaoDTO): PermissaoDTO" "Python"
                orquestrador = component "OrquestradorAcessoEnergia" "registrarEntrada(EntradaDTO): SessaoUsoDTO; aoReceberConfirmacaoEnergia()" "Python"
                repositorio = component "RepositorioSmartCampus" "obterAmbiente(), persistirAcesso(), atualizarStatusAmbiente()" "SQLAlchemy 2 / psycopg 3"
            }

            energia = container "Serviço de Energia" "Aplica Perfil Energético e Política de Agendamento; comanda atuadores" "Python 3.12, worker assíncrono"
            broker = container "Broker de Eventos" "Eventos de ocupação, confirmação de energia e alertas" "RabbitMQ 3.13" "Fila"
            db = container "Banco Smart Campus" "Usuários, permissões, ambientes, acessos imutáveis e sessões de uso" "PostgreSQL 16" "Banco"
            painel = container "Painel de Gestão" "Ocupação, consumo e alertas de desperdício" "React 18, TypeScript"
        }

        usuario -> terminal "Apresenta biometria" "Facial / digital"
        gestao -> painel "Consulta ocupação e alertas" "HTTPS"

        terminal -> controlador "solicitarAcesso()" "HTTPS/JSON (REST), mTLS"
        controlador -> identidade "validarCredencial()" "chamada síncrona"
        controlador -> permissao "verificarPermissao()" "chamada síncrona"
        controlador -> orquestrador "registrarEntrada()" "chamada síncrona"
        orquestrador -> repositorio "obterAmbiente(), persistirAcesso()" "chamada síncrona"
        repositorio -> db "Lê permissões e grava acessos" "SQL / psycopg 3"

        api -> broker "Publica EventoOcupacao e AlertaAcesso" "AMQP 0-9-1"
        broker -> energia "Entrega EventoOcupacao" "AMQP 0-9-1"
        energia -> broker "Publica ConfirmacaoEnergia" "AMQP 0-9-1"
        broker -> orquestrador "Entrega ConfirmacaoEnergia" "AMQP 0-9-1"
        energia -> iot "energizar()" "MQTT 3.1.1 sobre TLS"
        energia -> grade "Consulta aulas programadas" "HTTPS/JSON (REST)"
        painel -> api "Consulta dados e alertas" "HTTPS/JSON (REST)"
    }

    views {
        container smartCampus "Containers" "C4 Nível 2 - Contêineres" {
            include *
            autolayout lr
        }

        component api "Componentes" "C4 Nível 3 - Componentes da API de Acesso" {
            include *
            autolayout lr
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Externo" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Banco" {
                shape cylinder
            }
            element "Fila" {
                shape pipe
            }
        }
    }
}
