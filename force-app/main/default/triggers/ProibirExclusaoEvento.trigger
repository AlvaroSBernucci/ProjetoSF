trigger ProibirExclusaoEvento on Event (before delete) {
    // Lista para armazenar mensagens de erro
    List<String> mensagensErro = new List<String>();

    // Mapeia os IDs dos usuários criadores para os seus respectivos ProfileIds
    Map<Id, Id> criadoresParaProfileIds = new Map<Id, Id>();

    // Obtém os IDs dos usuários criadores dos eventos
    Set<Id> criadoresIds = new Set<Id>();
    for (Event evento : Trigger.old) {
        criadoresIds.add(evento.CreatedById);
    }

    // Consulta os ProfileIds associados aos usuários criadores
    Map<Id, User> criadoresParaUsuarios = new Map<Id, User>([SELECT Id, ProfileId FROM User WHERE Id IN :criadoresIds]);

    // Itera sobre os eventos para verificar as condições
    for (Event evento : Trigger.old) {
        // Obtém o ProfileId do criador do evento
        Id profileIdDoCriador = criadoresParaUsuarios.get(evento.CreatedById)?.ProfileId;

        // Obtém o ProfileId do usuário que está excluindo o evento
        Id profileIdDoUsuario = [SELECT ProfileId FROM User WHERE Id = :UserInfo.getUserId()].ProfileId;

        // Substitua 'ID_DO_PERFIL_DE_ADMINISTRADOR' pelo ProfileId do administrador
        if (profileIdDoUsuario != '00eHp000001hXBt' && profileIdDoCriador != '00eHp000001hXBt') {
            mensagensErro.add('Você não tem permissão para excluir eventos.');

            // Tenta encontrar a conta relacionada ao evento
            Id contaId = (evento.WhoId != null && String.valueOf(evento.WhoId.getSObjectType()) == 'Account') ? evento.WhoId : null;

            if (contaId != null) {
                // Marca o campo 'Contador__c' na conta
                try {
                    List<Account> contasRelacionadas = [SELECT Id, Contador__c FROM Account WHERE Id = :contaId LIMIT 1];
                    
                    if (!contasRelacionadas.isEmpty()) {
                        Account contaRelacionada = contasRelacionadas[0];
                        
                        // Incrementa o contador
                        Decimal novoContador = (contaRelacionada.Contador__c != null) ? contaRelacionada.Contador__c + 1 : 1;
                        contaRelacionada.Contador__c = novoContador;
                        update contaRelacionada;
                    }
                } catch (Exception e) {
                    // Trate a exceção conforme necessário
                    System.debug('Erro ao atualizar conta: ' + e.getMessage());
                }
            }
        }
    }

    // Se houver mensagens de erro, impede a exclusão e exibe as mensagens
    if (!mensagensErro.isEmpty()) {
        for (Event evento : Trigger.old) {
            evento.addError(mensagensErro[0]); // Adiciona a primeira mensagem de erro ao evento
        }
    }
}