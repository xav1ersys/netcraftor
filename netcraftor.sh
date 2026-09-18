#!/bin/bash

# ============================================================
#  NETCRAFT EXTRACTOR v1
#  by: xav1ersys | github.com/xav1ersys
# ============================================================
#
#  Consulta o Site Report público do Netcraft (sitereport.netcraft.com)
#  e extrai as tabelas de informação do JSON retornado pelo endpoint
#  ajax=dcg.
#
#  Chaves confirmadas ao vivo (via -keys) no JSON de resposta:
#    background_table, dmarc_table, spf_table, technology_table, webbugs
# ============================================================

BANNER=$(cat <<'BANNER_EOF'
 ,ggg, ,ggggggg,     ,ggggggg,  ,ggggggggggggggg  ,gggg,   ,ggggggggggg,              ,ggg, ,gggggggggggggg ,ggggggggggggggg  _,gggggg,_      ,ggggggggggg,   
dP""Y8,8P"""""Y8b  ,dP""""""Y8bdP""""""88""""""",88"""Y8b,dP"""88""""""Y8,           dP""8IdP""""""88""""""dP""""""88""""""",d8P""d8P"Y8b,   dP"""88""""""Y8, 
Yb, `8dP'     `88  d8'    a  Y8Yb,_    88      d8"     `Y8Yb,  88      `8b          dP   88Yb,_    88      Yb,_    88      ,d8'   Y8   "8b,dPYb,  88      `8b 
 `"  88'       88  88     "Y8P' `""    88     d8'   8b  d8 `"  88      ,8P         dP    88 `""    88       `""    88      d8'    `Ybaaad88P' `"  88      ,8P 
     88        88  `8baaaa             88    ,8I    "Y88P'     88aaaad8P"         ,8'    88     ggg88gggg          88      8P       `""""Y8       88aaaad8P"  
     88        88 ,d8P""""             88    I8'               88""""Yb,          d88888888        88   8          88      8b            d8       88""""Yb,   
     88        88 d8"                  88    d8                88     "8b   __   ,8"     88        88              88      Y8,          ,8P       88     "8b  
     88        88 Y8,            gg,   88    Y8,               88      `8i dP"  ,8P      Y8  gg,   88        gg,   88      `Y8,        ,8P'       88      `8i 
     88        Y8,`Yba,,_____,    "Yb,,8P    `Yba,,_____,      88       Yb,Yb,_,dP       `8b, "Yb,,8P         "Yb,,8P       `Y8b,,__,,d8P'        88       Yb,
     88        `Y8  `"Y8888888      "Y8P'      `"Y8888888      88        Y8 "Y8P"         `Y8   "Y8P'           "Y8P'         `"Y8888P"'          88        Y8
BANNER_EOF
)

BASE_URL="https://sitereport.netcraft.com/"

show_help() {
    echo "$BANNER"
    echo "NETCRAFT EXTRACTOR"
    echo "[ by: xav1ersys | github.com/xav1ersys ]"
    echo "[buffers] [networkcraft] [flags]"
    echo "+-------------------------------------------------------------------+"
    echo ""
    echo "  -h                  Show This Help Message"
    echo ""
    echo "  -host        target.com  Informações gerais (site title, rank,"
    echo "                           descrição, data de criação, idioma)"
    echo ""
    echo "  -dmarc       target.com  Registro DMARC do domínio"
    echo ""
    echo "  -spf         target.com  Registro SPF do domínio"
    echo ""
    echo "  -technology  target.com  Stack de tecnologias detectada"
    echo "                           (servidor web, CMS, linguagens, etc)"
    echo ""
    echo "  -webbugs     target.com  Web bugs / trackers de terceiros"
    echo "                           detectados no site"
    echo ""
    echo "  -all         target.com  Roda todas as consultas acima em sequência"
    echo ""
    echo "  -raw         target.com  Dump do JSON completo"
    echo ""
    echo "  -keys        target.com  Lista só as chaves de nível superior do"
    echo "                           JSON (útil se o Netcraft mudar a estrutura)"
    echo ""
    echo "  -o           file.txt    Salva a saída em um arquivo (usar junto"
    echo "                           com qualquer flag acima)"
    echo ""
    echo "+-------------------------------------------------------------------+"
}

# Normaliza o alvo (remove protocolo se já vier com http/https)
normalize_target() {
    local t="$1"
    t="${t#http://}"
    t="${t#https://}"
    echo "$t"
}

fetch_json() {
    local target
    target=$(normalize_target "$1")
    curl -sk "${BASE_URL}?url=https://${target}&ajax=dcg"
}

# Extrai conteúdo legível de uma seção HTML do Netcraft.
# Cobre os formatos reais observados no payload:
#   - tabelas simples label/valor (background_table)
#   - múltiplas <table> agrupadas por <h3> (technology_table)
#   - tabelas largas com várias colunas (webbugs)
#   - seções sem tabela nenhuma, só parágrafos de aviso
#     (dmarc_table / spf_table quando o domínio não tem registro)
# Usa perl em modo slurp (-0777) pra não depender de onde caem as
# quebras de linha dentro do HTML.
parse_table() {
    local html="$1"

    if ! command -v perl >/dev/null 2>&1; then
        echo "[!] 'perl' não encontrado (necessário pro parser). Instale com: apt install perl"
        return 1
    fi

    perl -0777 -ne '
        sub clean {
            my $s = shift;
            $s =~ s/<[^>]+>//g;
            $s =~ s/&nbsp;/ /g;
            $s =~ s/&amp;/&/g;
            $s =~ s/&quot;/"/g;
            $s =~ s/\s+/ /g;
            $s =~ s/^\s+|\s+$//g;
            return $s;
        }

        my $found_table = 0;

        # Percorre o HTML na ordem em que aparece, alternando entre
        # subtítulos <h3> (usados no technology_table) e <table>...</table>
        while (/(?:<h3[^>]*>(.*?)<\/h3>)|(?:<table[^>]*>(.*?)<\/table>)/gs) {
            if (defined $1) {
                print "\n-- " . clean($1) . " --\n";
            } elsif (defined $2) {
                $found_table = 1;
                my $table = $2;
                while ($table =~ /<tr[^>]*>(.*?)<\/tr>/gs) {
                    my $row = $1;
                    my @cells;
                    while ($row =~ /<t[hd][^>]*>(.*?)<\/t[hd]>/gs) {
                        my $c = clean($1);
                        push @cells, $c if length($c);
                    }
                    next unless @cells;
                    if (@cells == 2) {
                        print "$cells[0]: $cells[1]\n";
                    } else {
                        print join(" | ", @cells), "\n";
                    }
                }
            }
        }

        # Sem tabela nenhuma (ex: DMARC/SPF ausente) -> mostra os parágrafos
        unless ($found_table) {
            while (/<p[^>]*>(.*?)<\/p>/gs) {
                my $p = clean($1);
                print "$p\n" if length($p);
            }
        }
    ' <<< "$html"
}

# Dado um valor JSON (podendo ser string HTML, array ou objeto),
# imprime seu conteúdo da forma mais legível possível, sem assumir
# que toda chave é uma tabela HTML (ex: "webbugs" costuma ser array)
print_value() {
    local raw="$1" table_key="$2"
    local vtype
    vtype=$(echo "$raw" | jq -r --arg k "$table_key" '.[$k] | type' 2>/dev/null)

    case "$vtype" in
        string)
            local val
            val=$(echo "$raw" | jq -r --arg k "$table_key" '.[$k]')
            parse_table "$val"
            ;;
        array|object)
            echo "$raw" | jq --arg k "$table_key" '.[$k]'
            ;;
        null|"")
            return 1
            ;;
        *)
            echo "$raw" | jq -r --arg k "$table_key" '.[$k]'
            ;;
    esac
}

# Lista as chaves de nível superior do JSON retornado, pra descobrir
# os nomes reais das tabelas sem precisar adivinhar
list_keys() {
    local target="$1" raw
    raw=$(fetch_json "$target")

    if [ -z "$raw" ]; then
        echo "[!] Sem resposta do Netcraft para: $target"
        return 1
    fi

    if ! echo "$raw" | jq empty 2>/dev/null; then
        echo "[!] Resposta não é um JSON válido (provável erro/bloqueio no request)."
        echo "    Rode manualmente pra inspecionar: curl -sk \"${BASE_URL}?url=https://${target}&ajax=dcg\""
        return 1
    fi

    echo "== CHAVES DISPONÍVEIS NO JSON =="
    echo "$raw" | jq -r 'keys[]'
}

run_query() {
    local flag="$1" target="$2"
    local raw table_key label

    case "$flag" in
        host)
            table_key="background_table"
            label="INFORMAÇÕES GERAIS"
            ;;
        dmarc)
            table_key="dmarc_table"
            label="REGISTRO DMARC"
            ;;
        spf)
            table_key="spf_table"
            label="REGISTRO SPF"
            ;;
        technology)
            table_key="technology_table"
            label="TECNOLOGIAS DETECTADAS"
            ;;
        webbugs)
            table_key="webbugs"
            label="WEB BUGS / TRACKERS"
            ;;
    esac

    raw=$(fetch_json "$target")

    if [ -z "$raw" ]; then
        echo "[!] Sem resposta do Netcraft para: $target"
        return 1
    fi

    if ! echo "$raw" | jq empty 2>/dev/null; then
        echo "== $label =="
        echo "[!] Resposta não é um JSON válido (provável erro/bloqueio no request)."
        echo ""
        return 1
    fi

    echo "== $label =="
    if ! print_value "$raw" "$table_key"; then
        echo "[!] Chave '$table_key' não encontrada no JSON retornado."
        echo "    Rode '-keys $target' e confira os nomes disponíveis."
    fi
    echo ""
}

run_raw() {
    local target="$1"
    fetch_json "$target"
}

# ---------------- Parsing de argumentos ----------------
OUTFILE=""
ACTIONS=()
TARGET=""

if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -host|-dmarc|-spf|-technology|-webbugs)
            ACTIONS+=("${1#-}")
            shift
            TARGET="$1"
            shift
            ;;
        -all)
            ACTIONS+=("host" "dmarc" "spf" "technology" "webbugs")
            shift
            TARGET="$1"
            shift
            ;;
        -raw)
            ACTIONS+=("raw")
            shift
            TARGET="$1"
            shift
            ;;
        -keys)
            ACTIONS+=("keys")
            shift
            TARGET="$1"
            shift
            ;;
        -o)
            shift
            OUTFILE="$1"
            shift
            ;;
        *)
            echo "[!] Argumento desconhecido: $1"
            show_help
            exit 1
            ;;
    esac
done

if [ ${#ACTIONS[@]} -eq 0 ]; then
    show_help
    exit 0
fi

if [ -z "$TARGET" ]; then
    echo "[!] Nenhum alvo informado."
    exit 1
fi

run_all() {
    for act in "${ACTIONS[@]}"; do
        if [ "$act" == "raw" ]; then
            run_raw "$TARGET"
        elif [ "$act" == "keys" ]; then
            list_keys "$TARGET"
        else
            run_query "$act" "$TARGET"
        fi
    done
}

if [ -n "$OUTFILE" ]; then
    run_all | tee "$OUTFILE"
else
    run_all
fi
