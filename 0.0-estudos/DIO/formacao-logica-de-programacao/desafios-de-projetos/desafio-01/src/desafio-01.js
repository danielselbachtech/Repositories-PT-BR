// Criando as variáveis do herói
const NomeDoHeroi = "JackieChan";
let xpDoHeroi = 2000;
let nivel;

// Estruturas de decisões para classificar o nível com base no XP
switch (true) {
    case xpDoHeroi >= 0 && xpDoHeroi <= 1000:
        nivel = 'Ferro';
        break;
    case xpDoHeroi >= 1001 && xpDoHeroi <= 2000:
        nivel = 'Bronze';
        break;
    case xpDoHeroi >= 2001 && xpDoHeroi <= 5000:
        nivel = 'Prata';
        break;
    case xpDoHeroi >= 5001 && xpDoHeroi <= 7000:
        nivel = 'Ouro';
        break;
    case xpDoHeroi >= 7001 && xpDoHeroi <= 8000:
        nivel = 'Platina';
        break;
    case xpDoHeroi >= 8001 && xpDoHeroi <= 9000:
        nivel = 'Ascendente';
        break;
    case xpDoHeroi >= 9001 && xpDoHeroi <= 10000:
        nivel = 'Radiante';
        break;
    default:
        nivel = 'Desconhecido';
    }

// Saída exigida pelo desafio
console.log(`O Herói de nome ${NomeDoHeroi} está no nivel de ${nivel}!`);