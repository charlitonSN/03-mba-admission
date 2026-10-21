# MBA Admission: análise exploratória em SQL

Análise de 6.194 candidaturas a um programa de MBA para entender quem se candidata, quem é aprovado e quais características acompanham a aprovação. Todas as perguntas foram respondidas com SQL (SQLite).

O relatório completo, com tabelas, gráficos e a discussão de cada resultado, está em [`relatorio.pdf`](relatorio.pdf).

## Perguntas respondidas

1. Qual é a distribuição de gênero, nacionalidade, graduação e raça entre os candidatos?
2. Qual é a taxa de admissão de candidatos internacionais e de candidatos nacionais?
3. Qual é a média de GPA e de GMAT de cada um desses grupos?
4. Como se comparam as distribuições de GPA e GMAT entre os dois grupos?
5. A diferença entre as médias é estatisticamente significativa (teste t)?
6. Existe relação entre GPA e GMAT entre os admitidos?
7. Em quais indústrias a taxa de admissão é maior?
8. A experiência profissional tem correlação com a admissão?
9. Qual é a probabilidade de admissão para cada raça/etnia?
10. Há diferença de notas entre gêneros, considerando irrelevante uma diferença menor que 5%?
11. A experiência média de aprovados e não aprovados é diferente em cada gênero?

## Principais resultados

- A taxa geral de admissão é de 14,5% (900 de 6.194). Os admitidos têm GMAT médio de 692,7 e GPA de 3,35; os demais, 644,0 e 3,23.
- Nacionalidade não pesa: 15,1% dos internacionais e 14,3% dos nacionais foram admitidos. O teste t acusa diferença significativa no GPA, mas ela é de 0,01 ponto, sem efeito prático.
- Experiência profissional não tem relação com a admissão (r = 0,01).
- Investment Management (21,7%) e Financial Services (19,1%) têm as maiores taxas de admissão; Health Care (12,0%) e Energy (9,4%), as menores.
- Candidatos negros (8,7%) e hispânicos (10,4%) são admitidos bem menos que brancos (16,8%) e asiáticos (16,6%), embora todos os grupos cheguem com as mesmas notas médias.
- Mulheres têm taxa de admissão de 20,0%, contra 11,4% dos homens. O programa admitiu exatamente 450 pessoas de cada gênero. As diferenças de notas entre gêneros ficam abaixo de 5%.

## Dados

- Fonte: [MBA Admission dataset, Class 2025](https://www.kaggle.com/datasets/taweilo/mba-admission-dataset), no Kaggle.
- Segundo a página do dataset, os dados são sintéticos, gerados a partir das estatísticas da turma de 2025 da Wharton.
- `admission` vazio significa candidato recusado. A lista de espera (*Waitlist*) foi tratada como não admissão.
- `race` vazia corresponde aos candidatos internacionais, para os quais o dataset não registra raça.

## Como reproduzir

O banco `mba-admission.db` já está no repositório. Para gerá-lo do zero, baixe o `MBA.csv` e rode o script:

```bash
kaggle datasets download -d taweilo/mba-admission-dataset -p . --unzip
python gerar_banco.py
```

Depois, abra o banco em qualquer cliente SQLite (DB Browser for SQLite, DBeaver ou a extensão SQLite do VS Code) e execute as consultas de [`mba.sql`](mba.sql), que seguem a ordem das perguntas.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `mba.sql` | Consultas SQL de todas as perguntas |
| `relatorio.pdf` | Relatório com os resultados e a interpretação |
| `mba-admission.db` | Banco SQLite com a tabela `mba` |
| `gerar_banco.py` | Script que converte o CSV em banco SQLite |
| `perguntas.pdf` | Enunciado das perguntas de negócio |

## Ferramentas

SQLite, com funções de janela (`ROW_NUMBER`, `SUM() OVER`) e funções matemáticas (`SQRT`) para quartis, correlação de Pearson e teste t de Welch.

---

Charliton Nogueira · Projeto 03 do portfólio de análise de dados
