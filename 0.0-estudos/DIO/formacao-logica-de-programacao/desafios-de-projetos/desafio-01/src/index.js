const NomeDoHeroi = 'Esdras_O_Grande';
let XpDoHeroi = -1;
let NivelDoHeroi;

switch (true) {
    case  XpDoHeroi >= 0 && XpDoHeroi <= 1000:
        NivelDoHeroi = 'Ferro';
        break;
    case XpDoHeroi >= 1001 && XpDoHeroi <= 2000:
        NivelDoHeroi = 'Bronze';
        break;
    case XpDoHeroi >= 2001 && XpDoHeroi <= 5000:
        NivelDoHeroi = 'Prata';
        break;
    case XpDoHeroi >= 5001 && XpDoHeroi <= 7000:
        NivelDoHeroi = 'Ouro';
        break;
    case XpDoHeroi >= 7001 && XpDoHeroi <= 8000:
        NivelDoHeroi = 'Platina';
        break;
    case XpDoHeroi >= 8001 && XpDoHeroi <= 9000:
        NivelDoHeroi = 'Ascendente';
        break;
    case XpDoHeroi >= 9001 && XpDoHeroi <= 10000:
        NivelDoHeroi = 'Imortal';
        break;
    case XpDoHeroi > 10001:
        NivelDoHeroi = 'Radiante';
        break;
    default:
        NivelDoHeroi = 'Desconhecido';
}

// Saída
console.log(`O Herói de nome ${NomeDoHeroi} está no nível de ${NivelDoHeroi}!`);