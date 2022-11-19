    /*        
    Arthur Valls da Costa Silva - 120177470
    Bernardo Afonso Nunes - 121167931
    Julia Turazzi Almeida - 120188861
    */
%{
#include <stdio.h>
#include <string.h>
int columns = 1; /* Contador de colunas */
int unmatched = 1; /* Flag para saber se o token lido possui regex correspondente,
                      1 para unmatched (não existe regex correspondente) e 0 para matched (existe regex correspondente) */
%}

/* yylineno indica a linha do token lido */
%option yylineno

/* Estado para fazer a lógica de comentários aninhados */
%x COMMENT 

    /*  
    As seguintes linhas indicam as regex dos tokens que a linguagem aceita.
    Apenas os tokens indicados pela professora na atividade possuem regex correspondente abaixo.
    */
DIGITO [0-9] 
ID ({LETRA}|{DIGITO}|_)
LETRA ([a-z]|[A-Z])
whitespace    (\t|" "|\r)
float       -?{DIGITO}+\.{DIGITO}+
integer      (0|[1-9]{DIGITO}*)
identifier        ({LETRA}|_){ID}*
comment "/*"([^*]|\*+[^*/])*\*+"/"
single_comment \/[\/]+.*
nested_comment (\/\*(?:(?!\/\*|\*\/).|(?1))*\*\/)|((?:(?!(?1)).)+)
whiteline ^(?:[\t ]*(?:\r?\n|\r))+
unmatched .
    
    /*
    Como recomendado pela professora, as palavras e caracteres reservados retornam a si próprios
    na escrita dos tokens no arquivo output.txt
    */
char_reserved ("="|"("|")"|"{"|"}"|";"|","|":")
reserved ("if"|"else"|"while"|"var"|"return"|"fn"|"bool"|"int"|"float"|"true"|"false")
%%

%{
   int comment_nest = 0; /* variável que indica o nível de aninhamento do comentário */
%}


    /* 
        sempre que uma nova linha é encontrada,
        reiniciamos o contador de coluna de volta para 1,
        e adicionamos 1 unidade no contador de linha
    */
[\n] {columns = 1; return yylineno + 1;}

"/*"            BEGIN(COMMENT); ++comment_nest; /* troca o estado para COMMENT e incrementa nível de aninhamento*/
"//".*          /* comenta ate o fim da linha */                        
<COMMENT>[^*/]* /* "captura" delimitadores que não são comentários */   
<COMMENT>"/*"   ++comment_nest; /* incrementa nível de aninhamento */   
<COMMENT>"*/"   if (--comment_nest == 0){ BEGIN(INITIAL); } /* incrementa nível de aninhamento já que encontramos fim de um comentário*/   
<COMMENT>[*/]   /* "captura" / ou * se o mesmo não tiver uma sequência de comentários correspondentes */


    /* 
    As próximas 6 regras basicamente seguem o mesmo formato:

        A função yylex() lerá o token do arquivo input.txt e escreverá no arquivo output.txt a seguinte tupla:

            TOKEN    TIPO DO TOKEN     LINHA      INICIO COLUNA      FIM COLUNA
        
        Com a exceção do TIPO DO TOKEN, que é reconhecido pela própria regra utilizando as regex's que estabelecemos anteriormente,
        cada elemento da tupla é substituído/seguido por sua variável correspondente:

            yytext: representa o token
            yylineno: representa a linha na qual o token se encontra
            columns: representa a coluna na qual o token começa
            columns + yyleng - 1: representa a conta feita para indicar qual coluna o token termina (yyleng corresponde ao tamanho de caracteres do token)

        Para que a contagem de colunas aconteça, a cada token lido incrementamos o valor correspondente ao tamanho do token à variável columns.
        Caso o token seja lido, significa que ele possui regex correspondente em nosso código, e a flag de correspondencia é mudada para 0 (possui regex correspondente)
    */ 
{reserved} {fprintf(yyout, "%s    %s     LINHA %d     INICIO COLUNA %d     FIM COLUNA %d\n", yytext, yytext, yylineno, columns, columns + yyleng - 1);
columns += yyleng; unmatched = 0;}


{char_reserved} {fprintf(yyout, "%s       %s     LINHA %d     INICIO COLUNA %d     FIM COLUNA %d\n", yytext, yytext, yylineno, columns, columns + yyleng - 1);
columns += yyleng; unmatched = 0;}


{identifier} {fprintf(yyout, "%s       IDENTIFICADOR   LINHA %d     INICIO COLUNA %d     FIM COLUNA %d\n", yytext, yylineno, columns, columns + yyleng - 1);
        columns += yyleng; unmatched = 0;}


{integer} {fprintf(yyout, "%s       INTEIRO   LINHA %d     INICIO COLUNA %d     FIM COLUNA %d\n", yytext, yylineno, columns, columns + yyleng - 1);
    columns += yyleng; unmatched = 0;}


{float} {fprintf(yyout, "%s       FLOAT   LINHA %d    INICIO COLUNA %d     FIM COLUNA %d\n", yytext, yylineno, columns, columns + yyleng - 1);
    columns += yyleng; unmatched = 0;}


{single_comment} {fprintf(yyout, "%s       COMMENT   LINE %d     INICIO COLUNA %d     FIM COLUNA %d\n", yytext, yylineno, columns, columns + yyleng - 1);
    columns += yyleng; unmatched = 0;}

    /*
    A próxima regra contabiliza o número de espaços em branco entre palavras/tokens, adicionando esse número à variável columns para que
    a contabilização de colunas permaneça correta. 
    */
{whitespace} {columns += yyleng; unmatched = 0;}


    /*
    Similar as primeiras 6 regras, escreveremos uma tupla que contém os 5 elementos solicitados pela professora. Contudo, a seguinte regra só se aplicará
    para tokens que não possuam regex's correspondentes, ou seja, tokens desconhecidos.
    No final da regra mudaremos o estado de unmatched para 1 (não existe regex correspondente).
    */
{unmatched} {if(unmatched){fprintf(yyout, "TOKEN DESCONHECIDO LINE %d     INICIO COLUNA %d     FIM COLUNA %d\n", yylineno, columns, columns + yyleng - 1);
    columns += yyleng;} unmatched = 1;}
%%
int yywrap()
{
    return 1; /* como yywrap retorna 1, significa que o arquivo acabou e todos os tokens foram lidos*/
}
int main(){


   FILE *input_file = fopen("input.txt", "r");  /* abre o arquivo de input em modo "read" */
   FILE *output_file = fopen("output.txt", "w"); /* abre o arquivo de output em modo "write" */
   
   if(!input_file)
   {
    printf("ARQUIVO NÃO ENCONTRADO"); /* caso o arquivo não seja encontrado retornamos esse erro */
    return -1;
   }
   
   yyin = input_file;  /* variável yyin que determina o input para a funcao yylex() recebe o arquivo input.txt */
   yyout = output_file; /* variável yyout que determina o output para a funcao yylex() recebe o arquivo output.txt */
   
   /*
   Dependendo do seu compilador o formato do %d pode dar erro alegando que a variável a ser printada é um unsigned long int (%lu),
   porém esse warning também foi visto em outro compilador alegando o contrário (%lu para uma variável int)
   */
   
   while(yylex()); /* executa as regras em todos os tokens contidos no arquivo input */
   fclose(input_file); /* fecha o arquivo de input */
   fclose(output_file); /* fecha o arquivo de output */
}
