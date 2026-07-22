" Vim syntax file
" Language: Snakemake

if exists("b:current_syntax")
  finish
endif

runtime! syntax/python.vim
unlet! b:current_syntax

syntax keyword snakemakeKeyword rule checkpoint subworkflow module use ruleorder include configfile localrules onsuccess onerror onstart workdir wildcard_constraints container conda envvars scattergather report
syntax keyword snakemakeSection input output params resources threads priority log benchmark message shell script notebook wrapper run cwl cache shadow group retries version
syntax match snakemakeRuleName /^\s*\%(rule\|checkpoint\)\s\+\zs[A-Za-z_][A-Za-z0-9_]*/
syntax match snakemakeSectionLabel /^\s*\zs\%(input\|output\|params\|resources\|threads\|priority\|log\|benchmark\|message\|shell\|script\|notebook\|wrapper\|run\|cwl\|cache\|shadow\|group\|retries\|version\)\ze\s*:/

highlight default link snakemakeKeyword Keyword
highlight default link snakemakeSectionLabel Statement
highlight default link snakemakeSection Statement
highlight default link snakemakeRuleName Function

let b:current_syntax = "snakemake"
