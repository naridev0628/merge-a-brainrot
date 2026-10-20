--!strict
-- Core navigation and onboarding. Character proper names remain unchanged.
local Locale={}
local service=game:GetService('LocalizationService')
local language=string.lower(string.sub(service.RobloxLocaleId,1,2))
local column=({es=1,pt=2,fr=3})[language]
local phrases={
    ['Buy your first Brainrot!']={'¡Compra tu primer Brainrot!','Compre seu primeiro Brainrot!','Achète ton premier Brainrot !'},
    ['Walk onto BUY 1. Your starting $5 buys Tung Tung!']={'¡Pisa COMPRAR 1! Tus $5 iniciales compran Tung Tung.','Pise em COMPRAR 1. Seus $5 iniciais compram Tung Tung!','Marche sur ACHETER 1. Tes $5 de départ achètent Tung Tung !'},
    ['Collect 3 mini Tung Tungs!']={'¡Recoge 3 mini Tung Tungs!','Colete 3 mini Tung Tungs!','Ramasse 3 mini Tung Tungs !'},
    ['$5 - then you can make your first merge.']={'$5: después podrás fusionarlos.','$5: depois você pode fundi-los.','$5 : ensuite, tu pourras les fusionner.'},
    ['BUY FIRST']={'COMPRAR PRIMERO','PRIMEIRA COMPRA','PREMIER ACHAT'},
    ['You will receive']={'Recibirás','Você receberá','Tu recevras'},
    ['Requirement']={'Requisito','Requisito','Condition'},
    ['NO RESET']={'SIN REINICIO','SEM REINICIAR','SANS RÉINITIALISER'},
    ['REBIRTH']={'RENACER','RENASCER','RENAISSANCE'},
    ['Own a Level 6 Brainrot']={'Ten un Brainrot de nivel 6','Tenha um Brainrot nível 6','Possède un Brainrot de niveau 6'},
    ['Home']={'Inicio','Início','Accueil'},
    ['Merge']={'Fusionar','Fundir','Fusion'},
    ['Index']={'Índice','Índice','Index'},
    ['Rebirth']={'Renacer','Renascer','Renaissance'},
    ['Tutorial']={'Tutorial','Tutorial','Tutoriel'},
    ['Minis']={'Minis','Minis','Minis'},
    ['PERMANENT!']={'¡PERMANENTE!','PERMANENTE!','PERMANENT !'},
    ['Close']={'Cerrar','Fechar','Fermer'},
    ['Coming soon']={'Próximamente','Em breve','Bientôt'},
    ['Deposit Minis']={'Depositar Minis','Depositar Minis','Déposer les Minis'},
    ['Collect cash']={'Recoger dinero','Coletar dinheiro',"Récupérer l’argent"},
    ['Selling Mini Brainrots']={'Vendiendo Mini Brainrots','Vendendo Mini Brainrots','Vente des Mini Brainrots'},
    ['Finish now']={'Terminar ahora','Concluir agora','Terminer maintenant'},
    ['Finish all queued sales']={'Terminar todas las ventas','Concluir todas as vendas','Terminer toutes les ventes'},
    ['Finish now is coming soon.']={'Terminar ahora estará disponible pronto.','Concluir agora estará disponível em breve.','Terminer maintenant sera bientôt disponible.'},
    ['Available plot']={'Parcela disponible','Terreno disponível','Parcelle disponible'},
    ['Auto Collect']={'Recogida automática','Coleta automática','Collecte automatique'},
    ['Auto Sell']={'Venta automática','Venda automática','Vente automatique'},
    ['Auto']={'Auto','Auto','Auto'},
    ['Claim your first Brainrot!']={'¡Consigue tu primer Brainrot!','Pegue seu primeiro Brainrot !','Obtiens ton premier Brainrot !'},
    ['Follow the arrows to BUY 1 - it is FREE!']={'¡Sigue las flechas a COMPRAR 1: es GRATIS!','Siga as setas até COMPRAR 1: é GRÁTIS!','Suis les flèches vers ACHETER 1 : c’est GRATUIT !'},
    ['Collect 10 mini Tung Tungs!']={'¡Recoge 10 mini Tung Tungs!','Colete 10 mini Tung Tungs!','Ramasse 10 mini Tung Tungs !'},
    ['Deposit your Minis!']={'¡Deposita tus Minis!','Deposite seus Minis!','Dépose tes Minis !'},
    ['Take them to the deposit pad to start selling.']={'Llévalos a la plataforma de depósito.','Leve-os à plataforma de depósito.','Apporte-les à la plateforme de dépôt.'},
    ['Your Minis are selling!']={'¡Tus Minis se están vendiendo!','Seus Minis estão sendo vendidos!','Tes Minis sont en vente !'},
    ['Watch the processor. Collect cash when sales finish.']={'Mira el procesador. Recoge el dinero al terminar.','Observe o processador. Colete o dinheiro ao terminar.','Surveille le processeur. Récupère l’argent à la fin.'},
    ['Collect your cash!']={'¡Recoge tu dinero!','Colete seu dinheiro!','Récupère ton argent !'},
    ['Your Minis sold. Pick up the coins at the green pad.']={'Tus Minis se vendieron. Ve a la plataforma verde.','Seus Minis foram vendidos. Vá à plataforma verde.','Tes Minis sont vendus. Va sur la plateforme verte.'},
    ['Buy another Tung Tung!']={'¡Compra otro Tung Tung!','Compre outro Tung Tung!','Achète un autre Tung Tung !'},
    ['20 Coins - then you can make your first merge.']={'20 monedas: después podrás fusionarlos.','20 moedas: depois você pode fundi-los.','20 pièces : ensuite, tu pourras les fusionner.'},
    ['Merge two matching Brainrots!']={'¡Fusiona dos Brainrots iguales!','Funda dois Brainrots iguais!','Fusionne deux Brainrots identiques !'},
    ['Open Merge. Select a matching pair, then confirm.']={'Abre Fusionar. Elige dos iguales y confirma.','Abra Fundir. Escolha dois iguais e confirme.','Ouvre Fusion. Choisis deux identiques et confirme.'},
    ['Your farm, your rules!']={'¡Tu granja, tus reglas!','Sua fazenda, suas regras!','Ta ferme, tes règles !'},
    ['Grow your stack. Discover all six Brainrots.']={'Haz crecer tu granja. Descubre los seis Brainrots.','Expanda sua fazenda. Descubra os seis Brainrots.','Agrandis ta ferme. Découvre les six Brainrots.'},
    ['Welcome to Merge a Brainrot!']={'¡Bienvenido a Merge a Brainrot!','Bem-vindo a Merge a Brainrot!','Bienvenue dans Merge a Brainrot !'},
    ['Build a ridiculous stack of Brainrots. Start with $5 and buy your first Tung Tung!']={'¡Llena tu granja de Brainrots! Empieza con $5 y compra tu primer Tung Tung.','Encha sua fazenda de Brainrots! Comece com $5 e compre seu primeiro Tung Tung.','Remplis ta ferme de Brainrots ! Commence avec 5 $ et achète ton premier Tung Tung.'},
    ['1  Walk onto BUY 1 ($5)']={'1  Pisa COMPRAR 1 ($5)','1  Pise em COMPRAR 1 ($5)','1  Marche sur ACHETER 1 (5 $)'},
    ['2  Pick up its tiny copies']={'2  Recoge sus Minis','2  Colete seus Minis','2  Ramasse ses Minis'},
    ['3  Deposit, wait, collect Coins']={'3  Deposita, espera, recoge dinero','3  Deposite, espere, colete moedas','3  Dépose, attends, récupère les pièces'},
    ['4  Buy another and MERGE!']={'4  ¡Compra otro y FUSIONA!','4  Compre outro e FUNDA!','4  Achète un autre et FUSIONNE !'},
    ["Let's play!"]={'¡A jugar!','Vamos jogar!','Jouons !'},
    ['Brainrot Index']={'Índice de Brainrots','Índice de Brainrots','Index des Brainrots'},
    ['Discover all six tiers by merging matching pairs.']={'Descubre los seis niveles fusionando parejas iguales.','Descubra os seis níveis fundindo pares iguais.','Découvre les six niveaux en fusionnant des paires identiques.'},
    ['Merge your Brainrots!']={'¡Fusiona tus Brainrots!','Funda seus Brainrots!','Fusionne tes Brainrots !'},
    ['Confirm merge']={'Confirmar fusión','Confirmar fusão','Confirmer la fusion'},
    ['Select two matching Brainrots.']={'Elige dos Brainrots iguales.','Escolha dois Brainrots iguais.','Choisis deux Brainrots identiques.'},
    ['Merging is free and makes room in your stack.']={'Fusionar es gratis y libera espacio.','Fundir é grátis e libera espaço.','La fusion est gratuite et libère de la place.'},
    ['These Brainrots do not match.']={'Estos Brainrots no son iguales.','Estes Brainrots não são iguais.','Ces Brainrots sont différents.'},
    ['Waiting for server...']={'Esperando al servidor...','Aguardando o servidor...','En attente du serveur...'},
    ['Two matching Brainrots become one']={'Dos Brainrots iguales se convierten en uno','Dois Brainrots iguais viram um','Deux Brainrots identiques deviennent un'},
    ['Deposit Minis [E]']={'Depositar Minis [E]','Depositar Minis [E]','Déposer les Minis [E]'},
    ['Open Merge [E]']={'Abrir fusión [E]','Abrir fusão [E]','Ouvrir Fusion [E]'},
    ['Claim FREE Tung Tung [E]']={'Tung Tung GRATIS [E]','Tung Tung GRÁTIS [E]','Tung Tung GRATUIT [E]'},
    ['All sales complete']={'Ventas terminadas','Vendas concluídas','Ventes terminées'},
    ['Fully upgraded!']={'¡Mejoras al máximo!','Melhorias no máximo!','Améliorations maximales !'},
    ['Maximum reached - merge!']={'¡Límite alcanzado: fusiona!','Limite atingido: funda!','Limite atteinte : fusionne !'},
    ['A rare Lucky Block dropped!']={'¡Apareció un Lucky Block raro!','Apareceu um Lucky Block raro!','Un Lucky Block rare est apparu !'},
    ['See rewards and price [E]']={'Ver premios y precio [E]','Ver prêmios e preço [E]','Voir les récompenses et le prix [E]'},
    ['?  LUCKY BLOCK']={'?  LUCKY BLOCK','?  LUCKY BLOCK','?  LUCKY BLOCK'},
    ['One random Brainrot. Exact odds below.']={'Un Brainrot al azar. Probabilidades exactas abajo.','Um Brainrot aleatório. Chances exatas abaixo.','Un Brainrot aléatoire. Probabilités exactes ci-dessous.'},
    ['Stack full - merge first']={'Granja llena: fusiona primero','Fazenda cheia: funda primeiro','Ferme pleine : fusionne d’abord'},
    ['This block has already been opened.']={'Este bloque ya se abrió.','Este bloco já foi aberto.','Ce bloc a déjà été ouvert.'},
    ['Permanent boosts']={'Mejoras permanentes','Melhorias permanentes','Bonus permanents'},
    ['OWNED']={'COMPRADO','ADQUIRIDO','ACQUIS'},
    ['Ready to rebirth?']={'¿Listo para renacer?','Pronto para renascer?','Prêt à renaître ?'},
    ['Confirm rebirth and reset']={'Confirmar renacimiento y reinicio','Confirmar renascimento e reinício','Confirmer la renaissance et réinitialiser'},
    ['Bag full - deposit your Minis.']={'Bolsa llena: deposita tus Minis.','Bolsa cheia: deposite seus Minis.','Sac plein : dépose tes Minis.'},
    ['Not enough Coins. Deposit Minis, wait, then collect cash.']={'Faltan monedas. Deposita Minis, espera y recoge dinero.','Faltam moedas. Deposite Minis, espere e colete dinheiro.','Pas assez de pièces. Dépose des Minis, attends et récupère l’argent.'},
    ['Maximum amount of Brainrots reached. Merge your Brainrots.']={'Límite de Brainrots alcanzado. Fusiona tus Brainrots.','Limite de Brainrots atingido. Funda seus Brainrots.','Limite de Brainrots atteinte. Fusionne tes Brainrots.'},
}
local patterns={
    {'^(%d+)/3 Minis %- walk over their tiny copies%.$',{'%1/3 Minis: acércate a la bandeja central.','%1/3 Minis: vá até a bandeja central.','%1/3 Minis : approche du bac central.'}},
    {'^Level (%d+)$',{'Nivel %1','Nível %1','Niveau %1'}},
    {'^Rebirth (%d+)$',{'Renacer %1','Renascer %1','Renaissance %1'}},
    {'^(%d+) per second$',{'%1 por segundo','%1 por segundo','%1 par seconde'}},
    {'^%+(%d+) per second$',{'+%1 por segundo','+%1 por segundo','+%1 par seconde'}},
    {'^BUY (%d+)$',{'COMPRAR %1','COMPRAR %1','ACHETER %1'}},
    {'^Cost: (.+) Coins$',{'Precio: %1 monedas','Custo: %1 moedas','Prix : %1 pièces'}},
    {'^Unlock %- (.+) Coins$',{'Abrir: %1 monedas','Abrir: %1 moedas','Ouvrir : %1 pièces'}},
    {'^Collect (.+) Coins %[E%]$',{'Recoger %1 monedas [E]','Coletar %1 moedas [E]','Récupérer %1 pièces [E]'}},
    {'^Buy (%d+) %- (.+) Coins %[E%]$',{'Comprar %1: %2 monedas [E]','Comprar %1: %2 moedas [E]','Acheter %1 : %2 pièces [E]'}},
    {'^Upgrade %- (.+) Coins %[E%]$',{'Mejorar: %1 monedas [E]','Melhorar: %1 moedas [E]','Améliorer : %1 pièces [E]'}},
    {'^(%d+)/10 Minis %- walk over their tiny copies%.$',{'%1/10 Minis: acércate a la bandeja central.','%1/10 Minis: vá até a bandeja central.','%1/10 Minis : approche du bac central.'}},
    {'^(%d+) spaces left$',{'Quedan %1 espacios','Restam %1 espaços','%1 places restantes'}},
    {'^LOCKED %- Rebirth (%d+)$',{'BLOQUEADO: Renacer %1','BLOQUEADO: Renascer %1','VERROUILLÉ : Renaissance %1'}},
    {'^Unlocks at rebirth (%d+)$',{'Se desbloquea al renacer %1','Desbloqueia ao renascer %1','Se débloque à la renaissance %1'}},
    {'^Rebirth (%d+) required$',{'Requiere renacer %1','Requer renascer %1','Renaissance %1 requise'}},
    {'^Tier (%d+)$',{'Nivel %1','Nível %1','Niveau %1'}},
}
function Locale.translate(value: string): string
    if not column then return value end
    local direct=phrases[value]
    if direct then return direct[column] end
    local output={}
    for line in string.gmatch(value..'\n','(.-)\n') do
        local translated=phrases[line] and phrases[line][column] or line
        if translated==line then for _,rule in patterns do
            local replaced,count=string.gsub(line,rule[1],rule[2][column])
            if count>0 then translated=replaced; break end
        end end
        table.insert(output,translated)
    end
    return table.concat(output,'\n')
end
function Locale.bind(root: Instance)
    if not column then return end
    local function bind(instance: Instance)
        if not (instance:IsA('TextLabel') or instance:IsA('TextButton')) then return end
        local last=''
        local function update()
            if instance.Text==last then return end
            last=Locale.translate(instance.Text)
            if instance.Text~=last then instance.Text=last end
        end
        instance:GetPropertyChangedSignal('Text'):Connect(update); update()
    end
    for _,v in root:GetDescendants() do bind(v) end
    root.DescendantAdded:Connect(bind)
end
return Locale
