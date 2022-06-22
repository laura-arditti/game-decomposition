function [W] = interaction_graph(F, n_players, n_actions, arc_id)
% Per verificare se F è il flusso di un gioco grafico bisogna
% verificare F soddisfa la regola del parallelogramma. Più in generale,
% si può calcolare il grafo rispetto a cui F è flusso grafico e
% confrontarlo col grafo delle interazioni del gioco originale.

%  Per verificare la regola del parallelgramma bisogna controllare, per
%  ogni coppia di giocatori non adiacenti, che per ogni profilo strategico degli altri giocatori
% e per ogni coppia di loro azioni i flussi sui lati opposti del parallelogramma siano uguali.

W = zeros(n_players);

for i=1:n_players-1
    for j=i+1:n_players
        others = zeros(n_players-2,1);
        index=0;
        for m=1:n_players
            if m~=i && m~=j
                index=index+1;
                others(index)=m;
            end
        end
        for a=0:(n_actions^(n_players-2) -1)
            profile = zeros(n_players-2,1);
            s =  dec2bin(a,n_players-2);
            for k=1:length(s)
                profile(k)=str2num(s(k));
            end
            id_str = 1;
            for o=1:n_players-2
                id_str = id_str + profile(o)*2^(n_players-others(o));
            end

            % pi=0, pj=0
            v1 = id_str;
            % pi=0, pj=1
            v2 = id_str + 2^(n_players-j);
            % pi=1, pj=1
            v3 = id_str + 2^(n_players-j) + 2^(n_players-i);
            % pi=1, pj=0
            v4 = id_str + 2^(n_players-i);

            e1=arc_id(v1,v2);
            e2=arc_id(v2,v3);
            e3=arc_id(v3,v4);
            e4=arc_id(v4,v1);
               
            % Introduco una tolleranza nella verifica della condizione logica per
            % evitare errori di precisione
            if abs(F(e1)+F(e3))>0.01 || abs(F(e2)+ F(e4))>0.01
                W(i,j)=1;
                W(j,i)=1;

            end
        end
    end
end
end