% Si considera un gioco a 6 giocatori in cui ciascun giocatore ha lo stesso
% insieme di azioni {-1,+1}
n_players = 6;
n_actions = 2;
 
% Il grafo delle interazioni fra i giocatori è un 6-ciclo:
%     1 --- 2
%   /         \
%  6           3
%   \         /
%     5 --- 4
% Lo descrivo per mezzo della sua matrice di adiacenza W_int.
% La matrice M_int indica, per ogni arco nel grafo delle interazioni, quali sono i relativi nodi coda e
% testa. Definire M equivale a decidere una numerazione per gli archi: ad
% es. l'arco 1 sara'  d'ora in avanti l'arco che va dal nodo 1 al nodo 2.
% Ad ogni arco indiretto del grafo originale si associa una
% coppia di archi diretti, che corrispondono a una coppia di indici (i,i+1)
% nella matrice M_int.
M_int = zeros(2*n_players, 2);
for i = 1:n_players
    j = i+1;
    if j > n_players
        j = j - n_players;
    end
    M_int(2*i -1, :) = [i, j];
    M_int(2*i, :) = [j, i];
end

W_int = zeros(n_players,n_players);
narc= size(M_int,1);
for j=1:narc
    coda=M_int(j,1);
    testa=M_int(j,2);
    W_int(coda,testa)=1;
end

% Definisco le funzioni di utilita' dei giocatori come vettori aventi un
% numero di componenti pari al numero di strategie. Dato che lo spazio
% delle azioni dei singoli giocatori ha cardinalità due, numero le
% strategie dalla numero 0 (-1,-1,-1,-1) alla numero n_stragies-1
% (+1,+1,+1,+1) (in pratica considerando la strategia come un numero
% binario)

n_strategies = n_actions^n_players;

% I giocatori 1,3,4,5 giocano un majority game coi loro vicini, il giocatore
% 2 gioca un minority game.
% Codifico l'informazione sui giochi associati ai giocatori costruendo un
% vettore games in cui ad ogni giocatore e' associato un codice intero. In
% questo esempio:
%  - 0 = majority game
%  - 1 = minority game
% Raccolgo le funzioni utilita' in una matrice u: ogni colonna corrisponde
% a un giocatore.

u = zeros(n_strategies, n_players);
games = zeros(n_players,1);
%games(1)=1;
majority = games(:)==0;
minority = games(:)==1;

% utilita' dei giocatori che giocano minority (giocatore 2)
for p=1:n_players
    if minority(p)
        for i=0:n_strategies-1
            strategy = zeros(n_players,1);
            s =  dec2bin(i,n_players);
            for k=1:length(s)
                strategy(k)=str2num(s(k));
            end
            n_discord = 0;
            for j=1:n_players
                if W_int(p,j)==1
                    if strategy(j)~= strategy(p)
                        n_discord = n_discord+1;
                    end
                end
                u(i+1,p) = (n_discord)^2;
            end
        end
    end
end

% utilita' dei player che giocano majority (giocatori 1,3,4,5)
for p=1:n_players
    if majority(p)
        for i=0:n_strategies-1
        strategy = zeros(n_players,1);
        s =  dec2bin(i,n_players);
        for k=1:length(s)
            strategy(k)=str2num(s(k));
        end
            n_concord = 0;
            for j=1:n_players
                if W_int(p,j)==1
                    if strategy(j)== strategy(p)
                        n_concord = n_concord+1;
                    end
                end
                u(i+1,p) = n_concord^3*(strategy(p));
            end
        end
    end
end

% Costruisco il flusso X=Du associato al gioco e lo rappresento come una
% matrice di dimensione n_strategies x n_strategies. Per costruire X
% occorre sapere quali sono le strategie m-comparabili per ciascun
% giocatore m. Costruisco una matrice W_str che nella posizione (p,q)
% corrispondente alla coppia di strategia p e q contiene 
%  - 0 se le due strategie non sono comparabili
%  - m se le strategie sono m-comparabili

W_str = zeros(n_strategies);
M_str = zeros(n_strategies*n_players*(n_actions-1),2);
n_arcs = 0;
arc_id = zeros(n_strategies);

for i=0:n_strategies-2
    strategy1 = zeros(n_players,1);
    s1 =  dec2bin(i,n_players);
    for k=1:length(s1)
        strategy1(k)=str2num(s1(k));
    end
    for j=i+1:n_strategies-1 
        strategy2 = zeros(n_players,1);
        s2 =  dec2bin(j,n_players);
        for k=1:length(s2)
            strategy2(k)=str2num(s2(k));
        end
        
        num_diff=0;
        m=0;
        for n=1:n_players
            if strategy1(n)~=strategy2(n)
                num_diff=num_diff+1;
                m=n;
            end
        end
        
        if num_diff == 1
            W_str(i+1,j+1)=m;
            W_str(j+1,i+1)=m;
            n_arcs=n_arcs+1;
            M_str(n_arcs,1)=i;
            M_str(n_arcs,2)=j;
            arc_id(i+1,j+1)=n_arcs;
            n_arcs=n_arcs+1;
            M_str(n_arcs,1)=j;
            M_str(n_arcs,2)=i;
            arc_id(j+1,i+1)=n_arcs;
        end
    end
end

X = zeros(n_strategies);
for i=1:n_strategies
    for j=1:n_strategies
        if W_str(i,j)~=0
            m=W_str(i,j);
            X(i,j)= u(j,m)-u(i,m);
        end
    end
end

% Costruisco la matrice di D0 associata al gradiente combinatorio, cioe' la
% matrice di incidenza archi-nodi del grafo delle strategie. La matrice
% D0_star associata alla divergenza è la sua trasposta.

D0 = zeros(n_arcs,n_strategies);
for j=1:n_arcs
    coda=M_str(j,1)+1;
    testa=M_str(j,2)+1;
    D0(j,coda)=-1;
    D0(j,testa)=1;
end

% La matrice di proiezione P sull'immagine di D0 è D0*pinv(D0) dove
% pinv(D0) e' la pseudoinversa di Moore-Penrose di D0.

P = D0*pinv(D0);

% Rappresento il flusso X (matrice n_strategies x n_strategies) come
% vettore F di dimensione n_strategies^2 che associa ad ogni arco diretto sul grafo delle
% strategie il suo flusso.

F= zeros(n_arcs,1);
for e=1:n_arcs
    F(e)=X(M_str(e,1)+1,M_str(e,2)+1);
end

% La componente potenziale del flusso F_pot si ottiene facendo la
% proiezione di F sull'immagine di D0.

F_pot = P*F;

% W_pot e' la matrice di adiacenza del grafo rispetto a cui F_pot e'
% grafico, cioe' rispetta la regola dei parallelogrammi.
W_pot = interaction_graph(F_pot, n_players, n_actions, arc_id);

F_har = F - F_pot;
W_har = interaction_graph(F_har, n_players, n_actions, arc_id);

% % Rappresentazione grafica del flusso e della sua componente potenziale.
% nodenames = char(ones(n_strategies,n_players)*'0');
% for n=1:n_strategies
%     nodenames(n,:) = dec2bin(n-1, n_players);
% end
% nodenames = string(nodenames);
% M_str_ind = M_str(1:2:end, :);
% M_str_ind = M_str_ind + 1;
% s = M_str_ind(:,1);
% t = M_str_ind(:,2);
% weights = F(2:2:end);
% G_str = graph(s, t, weights, nodenames);
% figure(1)
% subplot(1, 2, 1);
% pic = plot(G_str);
% pic.EdgeCData = weights;
% axis equal
% title F
% subplot(1, 2, 2);
% weights=F_pot(2:2:end);
% pic_Fpot = plot(G_str);
% pic_Fpot.EdgeCData = weights;
% axis equal
% title F_{pot}

% Calcolo delle funzioni di utilità dell'unico gioco potenziale grafico
% (rispetto al grafo W_pot)
% normalizzato che produce la componente potenziale del flusso.
% L'unico gioco normalizzato che produce il flusso X_pot e' potenziale e
% grafico rispetto a W_pot e puo' essere ottenuto normalizzando un
% qualunque gioco che produce X_pot. In particolare, si puo' considerare il
% gioco u_pot in cui tutti i giocatori hanno utilita' uguale al potenziale
% phi associato a F_pot.

phi = pinv(D0)*F;
u_pot = zeros(n_strategies,n_players);
for p=1:n_players
    u_pot(:,p)=phi;
end

% Normalizzo il gioco imponendo che per ogni p_(-i) fissato, la somma delle
% utilita' u_i(p_i,p_(-i)) del giocatore i al variare della sua azione p_i
% abbiano somma 0.
for p=1:n_players
    for i=0:(n_actions^(n_players-1) -1)
        strategy = zeros(n_players-1,1);
        s =  dec2bin(i,n_players-1);
            for k=1:length(s)
                strategy(k)=str2num(s(k));
            end
        profile = zeros(n_players,1);
        sum=0;
        positions = false(n_strategies);
        for a=0:n_actions-1
            profile(p)=a;
            profile(1:n_players ~= p)=strategy;
            id_prof = 1;
            for g=1:n_players
                id_prof = id_prof + profile(g)*2^(n_players-g);
            end
            sum = sum + u_pot(id_prof,p);
            positions(id_prof)=true;
        end
        mean= sum/n_actions;
        u_pot(positions,p)=u_pot(positions,p)-mean;
    end
end
u_pot

% L'utilita' della componente armonica normalizzata del gioco si ottiene
% normalizzando u-u_pot.

u_har = u-u_pot;
for p=1:n_players
    for i=0:(n_actions^(n_players-1) -1)
        strategy = zeros(n_players-1,1);
        s =  dec2bin(i,n_players-1);
            for k=1:length(s)
                strategy(k)=str2num(s(k));
            end
        profile = zeros(n_players,1);
        sum=0;
        positions = false(n_strategies);
        for a=0:n_actions-1
            profile(p)=a;
            profile(1:n_players ~= p)=strategy;
            id_prof = 1;
            for g=1:n_players
                id_prof = id_prof + profile(g)*2^(n_players-g);
            end
            sum = sum + u_har(id_prof,p);
            positions(id_prof)=true;
        end
        mean= sum/n_actions;
        u_har(positions,p)=u_har(positions,p)-mean;
    end
end
u_har

% Rappresentazione del grafo delle interazioni e del grafo rispetto a cui
% il gioco potenziale e' grafico.
G_int = graph(W_int);
G_pot = graph(W_pot);
G_har = graph(W_har);
figure(2)
subplot(2, 2, 1);
pic_int = plot(G_int);
highlight(pic_int,minority,'NodeColor','r')
axis equal
title G_{int}
subplot(2, 2, 2);
pic_pot = plot(G_pot);
pic_pot.XData = pic_int.XData;
pic_pot.YData = pic_int.YData;
axis equal
title G_{pot}
subplot(2, 2, 3);
pic_har = plot(G_har);
pic_har.XData = pic_int.XData;
pic_har.YData = pic_int.YData;
axis equal
title G_{har}

% % Rappresentazione grafica delle utilita'. Per ogni giocatore si
% % rappresenta un grafo delle strategie in cui i nodi sono colorati in base
% % al valore dell'utilita'.
% 
% % Gioco iniziale u
% figure(3)
% %title('Utilita del gioco di partenza')
% for p=1:n_players
%     subplot(2, 3, p);
%     pic = plot(G_str);
%     pic.NodeCData = u(:,p);
%     axis equal 
%     tit = sprintf('u(%d)',p);
%     title (tit) 
% end
% 
% % Componente potenziale
% figure(4)
% %title('Utilita della componente potenziale')
% for p=1:n_players
%     subplot(2, 3, p);
%     pic = plot(G_str);
%     pic.NodeCData = u_pot(:,p);
%     axis equal
%     tit = sprintf('u_{pot}(%d)',p);
%     title (tit) 
% end
% 
% % Componente armonica
% figure(5)
% %title('Utilita della componente armonica')
% for p=1:n_players 
%     subplot(2, 3, p);
%     pic = plot(G_str);
%     pic.NodeCData = u_har(:,p);
%     axis equal
%      tit = sprintf('u_{har}(%d)',p);
%     title (tit)  
% end
