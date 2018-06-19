pragma solidity ^0.4.6;
 
//Para este trabalho, os atores "Manufaturador", "Transportador", "Armazem" e "Produtor" são considerados entidades importantes para refererência ao rastrear
// a cadeia. Por este motivo, foi criado este contrato genérico no qual será herdado por todas esses contratos, que serão empresas;
contract Empresa{
    //O nome da empresa;
    string nome;
    // O Endereco se refere a "Account" neste caso;
    address endereco;
   
}
 
// Esta implementação ainda não está ideal, o objetivo de criar o "Estoque" como algo abstrato é para reduzir redundância nas contratos que tem como natureza 
// "estocar" algum produto produzido que será posteriormente processado. Estou ciente que o nome não é dos mais adequados, então sugiro a modificação deste
// nome para trabalhos posteriores. No caso, ela será herdada pelo "Produtor", pelo "Manufaturador" e pelo "Armazém", visto que todos eles possuem a característica
// de armazenar e encaminhar produtos para uma outra empresa;
contract Estoque{
    
    // Esta variável, estoque, será responsavel por identificar os produtos que serão encaminhados para uma unidade posterior;
    Produto[] estoque;
    // Esta variável sera o identificador da "Account" do destino do produto;
    address destinoProduto;
   
    // Essa função tem como objetivo atualizar/definir o destino atual do conteúdo em estoque.
    function setDestino(address _enderecoArmazem) public {
        destinoProduto = _enderecoArmazem;
    }
   
    // Essa função utiliza a "Account" de algum transportador no qual será responsável pelo transporte;
    function encaminha(Transportadora transportadorResponsavel) public{
          // O "Pacote" será explicado posteriormente. Ele é só um contrato onde possuí um produto e um destino, assim o transportador
          // pode transportar para outro transportador sem problemas. Para criar o pacote, utiliza-se o produto no topo do array de produtos
          // e o destino do produto;
          Pacote pacoteParaEntrega= new Pacote(destinoProduto, estoque[estoque.length-1]);
          // Tratamento do array de produtos;
          delete estoque[estoque.length-1];
          estoque.length--;
          // Encaminha o pacote para o transportador realizar a entrega;
          transportadorResponsavel.entrega(pacoteParaEntrega);
     }
     
     // Esta função está mal implementada. Contudo, quando deixada ela de forma abstrata ( sem as chaves), o programa não compilava mesmo depois de definir
     // explicitamente a função dentro das outras que herdam esse contrato. Não foi possível solucionar o problema durante o tempo do trabalho.
     function recebe(Produto _produtoRecebido) public{
     }
     
}
 
// O produtor, conforme definido no planejamento, é um tipo especial de Manufaturador, ele não possuí nenhuma matéria prima como insumo, então ele pode produzir
// "produtos" a partir do "nada"
contract Produtor is Empresa, Estoque{
 
    // Seu construtor se restringe a definir os seus atributos herdados de "Empresa", visto que o Produtor é uma empresa relevante para o rastreamento.
     constructor(string _nome) public {
        nome = _nome;
        endereco = msg.sender;
     }
     
     // Este método simplesmente produz o "Produto" matéria prima, que será o produto mais básico de toda a cadeia.
     function produzMateriaPrima() public {
          // Cria o produto novo;
          Produto novoProduto = new Produto("Ferro", "materia prima", endereco);
          // Adiciona ao estoque;
          estoque.push(novoProduto);
     }
     
}
 
// Conforme a execução do trabalho, acreditou-se que ao invés de transportar diretamente o produto de uma posição "A" para "B" seria mais elegante construir
// um "Pacote". O Pacote contém a informação do destino do produto e, também, os produtos que ele contém.
contract Pacote {
   
    address enderecoDestino;
    Produto produtoTransportado;
   
    // Seu constutor se restringe a definir o endereço destino e o produto que ele está transportando. Atualmente ele só pode transportar um produto, mas aqui
    // já fica uma sugestão, para trabalhos posteriores, de utilizar alguma outra forma de armazenamento para transporte, seja ele array, uma lista, etc.
    constructor(address _enderecoDestino, Produto _produtoTransportado) public{
       
        enderecoDestino = _enderecoDestino;
        produtoTransportado = _produtoTransportado;
    }
   
    // Função para obter o endereço destino
    function getEnderecoDestino()public view returns (address){
        return enderecoDestino;
    }
   
    // Função para obter o produto do pacote. Aqui seria interessante "destruir" o pacote após a utilização deste método, visto que o motivo do pacote é
    // o de fornecer o produto ao seu destinatário;
    function getProduto() public view returns (Produto){
        return produtoTransportado;
    }
   
}
 
//O armazem é outra "Empresa" importante para o rastreamento e, também, exerce as funções básicas de "Estoque". O planejamento pede que no Armazém
// seja salvo o momento em que o produto chega e que o produto sai. Para um trabalho mais elaborado, seria interessante utilizar identificadores
// mais precisos para referenciar qual produto que chegou em cada momento. Mas, nesse primeiro estagio do projeto, vamos só armazenar o tempo de entrada
// e de saída do ultimo produto.
contract Armazem is Empresa, Estoque{
 
    //Seu construtor se restringe a definir os seus atributos herdados de "Empresa"
    constructor(string _nome) public {
        nome = _nome;
        endereco = msg.sender;
     }
   
    //A maioria das implementações de recebe será dessa forma, com exceção do "Manufaturador".
    function recebe(Produto _produtoRecebido) public{
         estoque.push(_produtoRecebido);
         // Quando o produto é recebido e adicionado ao estoque, é o momento de atualizar o seu proprietario
         _produtoRecebido.setProprietario(endereco);
     }
   
}
 
// Aqui é um exemplo de má implementação do código e ele deveria ser revisado. O objetivo desse contrato era de criar duas instâncias, uma para produzir apenas
// "Dobradiças" a partir de "Ferro" e outra, para para produzir "Portas retráteis" a partir de "Dobradiças" e de mais "Ferro" No final das contas,
// foi criado apenas um Manufaturador que produz as duas coisas, desde que ele possua em seu estoque de produção as devidas quantidades para produção.
// Todos os produtos produzidos pelo Manufaturador são encaminhados para o estoque, mantendo a lógica do contrato "Estoque" e impedindo que ele produza 
// o próprio insumo. Ele possuí uma lógica diferente no método "recebe" pois ele precis identificar o tipo do produto que chega antes de alocar;
contract Manufaturador is Empresa, Estoque{
    //Este estoque é para consumo próprio durante a produção
    Produto[] estoqueDeDobradica;
    Produto[] estoqueDeFerro;
   
    // Manufaturador é uma "Empresa" no qual é relevante para a rastreabilidade.
    constructor(string _nome) public {
        nome = _nome;
        endereco = msg.sender;
     }
   
    // Ele implementa diferente o método "recebe" do estoque, pois, como ele é um dos utilizadores de produtos, ele deve alocar o local devido para o produto em suas própria cadeia de
    // produção. No exemplo, ele aloca "Ferro" no estoqueDeFerro e aloca o resto no estoqueDeDobradica;
    function recebe(Produto _produtoRecebido) public{
        if(compareStrings(_produtoRecebido.getTipoProduto(), "materia prima")){
            estoqueDeFerro.push(_produtoRecebido);
        }else {
            estoqueDeDobradica.push(_produtoRecebido);
        }
        // Quando o produto é recebido e adicionado ao estoque, é o momento de atualizar o seu proprietario
        _produtoRecebido.setProprietario(endereco);
     }
   
    // Não foi encontrado métodos nativos para comparação de strings, sendo assim, foi criado o seguinte método para isso.
    function compareStrings (string a, string b)private pure returns (bool){
       return keccak256(a) == keccak256(b);
   }
   
   // Para produzir dobradica se usa a matéria prima "Ferro". Utiliza-se somente uma unidade para o exemplo. Para a produção do novo produto ( a dobradica), é necessário resgatar o valor atual
   // da cadeia de forma a manter a integridade dela.
   function produzDobradica() public {
          // Aqui é resgatado a cadeiaAtual do ferro para, depois ser adicionado à cadeia do produto novo, a dobradica;
          address[] memory cadeiaAtual = estoqueDeFerro[estoqueDeFerro.length-1].getCadeia();
          // Tratamento do array do estoque de consumo para produção
          delete estoqueDeFerro[estoqueDeFerro.length-1];
          estoqueDeFerro.length--;
          Produto novoProduto = new Produto("Dobradica", "insumo", endereco);
          // Agora, depois da confirmação da criação do novo produto, é onde adicionamos o valor anterior da cadeia para o produto novo;
          // Temos um problema especial aqui, visto que ao produzir um novo produto adicionamos o proprietario atual como o próprio produtor
          // E, ao utilizar um produto de estoque de consumo, estaremos duplicando o proprietario atual. 
          novoProduto.setCadeia(cadeiaAtual);
          estoque.push(novoProduto);
     }
     
    function teste() public {
        estoque[estoque.length-1].getCadeia();
        estoque[estoque.length-1].getTipoProduto();
    }
   
    // Para produzir porta retratil, utiliza-se a matéria prima "Ferro" e "Dobradica". Para tal fim, utiliza-se somente uma unidade de cada uma.
    function produzPortaRetratil() public {
          // Aqui é resgatado a cadeiaAtual do ferro para, depois ser adicionado à cadeia do produto novo, a porta retratil;
          address[] memory cadeiaAtual1 =  estoqueDeFerro[estoqueDeFerro.length-1].getCadeia();
          // Aqui é resgatado a cadeiaAtual da dobradica para, depois ser adicionado à cadeia do produto novo, a porta retratil;
          address[] memory cadeiaAtual2 =  estoqueDeDobradica[estoqueDeDobradica.length-1].getCadeia();
          // Tratamento do array do estoque de consumo para produção
          delete estoqueDeFerro[estoqueDeFerro.length-1];
          estoqueDeFerro.length--;
          // Tratamento do array do estoque de consumo para produção
          delete estoqueDeDobradica[estoqueDeDobradica.length-1];
          estoqueDeDobradica.length--;
          Produto novoProduto = new Produto("Porta retratil", "insumo", endereco);
          //Agora, depois da confirmação da criação do novo produto, é onde adicionamos o valor anterior das cadeia para ao produto novo( a porta retrátil);
          novoProduto.setCadeia(cadeiaAtual1);
          novoProduto.setCadeia(cadeiaAtual2);
          estoque.push(novoProduto);
     }
   
}
 
//A Transportadora é outra "Empresa" importante para o rastreamento, contudo, diferente dos outros participantes, ela não é um Estoque, ela somente é responsável pelo transporte de "A" para "B"
contract Transportadora is Empresa{
   
    constructor(string _nome) public {
        nome = _nome;
        endereco = msg.sender;
     }
    // Entrega para o destino 
    function entrega(Pacote pacoteParaEntrega) public{
        address enderecoDestino = pacoteParaEntrega.getEnderecoDestino();
        // Define o transportador como proprietario atual do produto
        pacoteParaEntrega.getProduto().setProprietario(endereco);
        Estoque(enderecoDestino).recebe(pacoteParaEntrega.getProduto());
    }
}
 
contract Produto {
   
    // Nome do produto
    string nome;
    // O tipoDoProduto é para o manufaturador identificar aonde alocar o produto, por enquanto só é relevante se ele é matéria prima ou não.
    string tipoProduto;
    // O proprietario atual do produto;
    address proprietario;
    // O produtor se refere a quem produziu ele;
    address produtor;
    // Array de tadas as empresas que tocaram no produto
    address[] cadeia;
   
   // Construtor se restringe a definir o nome do produto, o seu tipo, quem é o seu produtor. Se torna implícito que, durante a criação, o proprietario
   // seja o proprio produtor.
   constructor(string _nome, string _tipoProduto, address _produtorOrigem) public{
       
        nome = _nome;
        tipoProduto = _tipoProduto;
        produtor = _produtorOrigem;
        setProprietario(_produtorOrigem);
    }
    
    
    // Essa funcao deve ser chamada toda vez que o produto mudar de proprietario, seja no momento da produção, durante transporte ou no recebimento
    function setProprietario(address _novoProprietario) public{
        proprietario = _novoProprietario;
        cadeia.push(proprietario);
    }
    
    // Retorna o tipo do produto
    function getTipoProduto() public view returns(string){
        return tipoProduto;
    }
    
    // Retorna a cadeia inteira atual
    function getCadeia() public constant returns(address[]){
        return cadeia;
    }
   
   // Adiciona no final do array da cadeia os valores extras de membros da cadeia. Isso deve ser chamado toda vez que o produto for utilizado para criar
   // um novo produto. Lembrando que é impossível remover os membros da cadeia depois de terem sido adicionados. O problem atual dessa implementação
   // é o de não conseguir armazenar de forma cronológica as empresas e uma duplicação do código de rastreamento ao utilizar um produto como matéria prima.
    function setCadeia(address[] cadeiaAtual) public returns(address[]){
        for( uint i = 0; i<cadeiaAtual.length-1;i++){
            cadeia.push(cadeiaAtual[i]);
        }
    }
   
}
