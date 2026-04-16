// Nome do Herói
const NomeDoHeroi = "JackieChan";

// Função principal que calcula o saldo e define o nível do jogador
function calcularRank(vitorias, derrotas) {
    // Operador de subtração para calcular o saldo
    let saldoVitorias = vitorias - derrotas;
    let nivel = "";

    // Estruturas de decisões para classificar o nível com base nas vitórias
    if (vitorias < 10) {
        nivel = "Ferro";
    } else if (vitorias >= 11 && vitorias <= 20) {
        nivel = "Bronze";
    } else if (vitorias >= 21 && vitorias <= 50) {
        nivel = "Prata";
    } else if (vitorias >= 51 && vitorias <= 80) {
        nivel = "Ouro";
    } else if (vitorias >= 81 && vitorias <= 90) {
        nivel = "Diamante";
    } else if (vitorias >= 91 && vitorias <= 100) {
        nivel = "Lendário";
    } else if (vitorias >= 101) {
        nivel = "Imortal";
    }

    // Retorna um objeto contendo os dois resultados
    return { saldo: saldoVitorias, rank: nivel };
}

// Criando uma lista de simulações para aplicar o Laço de Repetição
let partidas = [
    { vitorias: 8, derrotas: 2 },
    { vitorias: 45, derrotas: 10 },
    { vitorias: 120, derrotas: 5 }
];

// Laço de repetição para testar vários casos de uma vez
for (let i = 0; i < partidas.length; i++) {
    let resultado = calcularRank(partidas[i].vitorias, partidas[i].derrotas);
    
    // Saída exata exigida pelo desafio
    console.log(`O ${NomeDoHeroi} tem de saldo de ${resultado.saldo} está no nível de ${resultado.rank}`);
}