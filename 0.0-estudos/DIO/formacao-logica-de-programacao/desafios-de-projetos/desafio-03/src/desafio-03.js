// Classe base para o sistema de personagens
class Heroi {
    constructor(nome, idade, tipo) {
        this.nome = nome;
        this.idade = idade;
        this.tipo = tipo;
    }

    // Lógica para definir o tipo de ataque com base na classe do herói
    atacar() {
        let ataque;

    // Switch para tratar as condições de ataque de forma limpa
    switch (this.tipo.toLowerCase()) {
        case 'mago':
            ataque = 'magia';
            break;
        case 'guerreiro':
            ataque = 'espada';
            break;
        case 'monge':
            ataque = 'artes marciais';
            break;
        case 'ninja':
            ataque = 'shuriken';
            break;
        default:
            ataque = 'um ataque indefinido';
    }

    // Saída formatada conforme requisito do projeto
    console.log(`O ${this.tipo} atacou usando ${ataque}`);
    }
}

// Instanciando objetos para validar os requisitos
const heroiUm = new Heroi("Gandalf", 2.000, "mago");
const heroiDois = new Heroi("Conan", 35, "guerreiro");
const heroiTres = new Heroi("Bruce", 40, "monge");
const heroiQuatro = new Heroi("Hanzo", 28, "ninja");

// Execução dos ataques
heroiUm.atacar();
heroiDois.atacar();
heroiTres.atacar();
heroiQuatro.atacar();