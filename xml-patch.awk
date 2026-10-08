# 只移除三个空的 GMS 节点；不删除整行，不改注释和其他节点。
# 不完整 XML、DTD 和非空目标节点拒绝输出，安装时保留原文件。
{xml=xml $0 ORS}
function fail() {bad=1; exit 2}
function attributes(s,    key,q,end,value) {
    package=""; delete seen
    while(length(s)) {
        sub(/^[ \t\r\n]+/, "", s)
        if(s=="") return
        if(!match(s,/^[A-Za-z_:][A-Za-z0-9_.:-]*/)) fail()
        key=substr(s,1,RLENGTH); s=substr(s,RLENGTH+1)
        if(seen[key]++) fail()
        sub(/^[ \t\r\n]*=[ \t\r\n]*/, "=", s)
        if(substr(s,1,1)!="=") fail()
        s=substr(s,2); q=substr(s,1,1)
        if(q!="\"" && q!=sprintf("%c",39)) fail()
        s=substr(s,2); end=index(s,q); if(!end) fail()
        value=substr(s,1,end-1); s=substr(s,end+1)
        if(key=="package") package=value
    }
}
END {
    if(bad) exit 2
    pos=1; depth=0; roots=0; out=""
    while(pos<=length(xml)) {
        rest=substr(xml,pos); open=index(rest,"<")
        if(!open) {if(depth==0 && rest !~ /^[ \t\r\n]*$/) fail(); out=out rest; break}
        text=substr(rest,1,open-1)
        if(depth==0 && text !~ /^[ \t\r\n]*$/) fail()
        out=out text; pos+=open-1; rest=substr(xml,pos)
        if(substr(rest,1,4)=="<!--") {
            end=index(substr(rest,5),"-->"); if(!end) fail()
            len=end+6
        } else if(substr(rest,1,9)=="<![CDATA[") {
            if(!depth) fail()
            end=index(substr(rest,10),"]]>"); if(!end) fail()
            len=end+11
        } else {
            if(substr(rest,1,2)=="<!") fail()
            quote=""; len=0
            for(i=2;i<=length(rest);i++) {
                ch=substr(rest,i,1)
                if(quote!="") {if(ch==quote) quote=""}
                else if(ch=="\"" || ch==sprintf("%c",39)) quote=ch
                else if(ch==">") {len=i; break}
            }
            if(!len || quote!="") fail()
        }
        token=substr(rest,1,len); pos+=len
        if(substr(token,1,2)=="<?" || substr(token,1,2)=="<!") {out=out token; continue}
        body=substr(token,2,length(token)-2)
        if(substr(body,1,1)=="/") {
            name=substr(body,2); sub(/[ \t\r\n]+$/, "", name)
            if(!depth || stack[depth]!=name) fail()
            depth--; out=out token; continue
        }
        if(!match(body,/^[A-Za-z_:][A-Za-z0-9_.:-]*/)) fail()
        name=substr(body,1,RLENGTH); attrs=substr(body,RLENGTH+1)
        selfclose=(body ~ /\/[ \t\r\n]*$/)
        sub(/[ \t\r\n]+$/, "", attrs)
        if(selfclose) sub(/\/$/, "", attrs)
        attributes(attrs)
        target=(name=="allow-in-power-save" || name=="allow-in-power-save-except-idle" || name=="allow-in-data-usage-save") && package=="com.google.android.gms"
        if(target) {
            if(!depth) fail()
            if(!selfclose) {
                tail=substr(xml,pos)
                if(!match(tail,/^[ \t\r\n]*<\/[A-Za-z0-9_.:-]+[ \t\r\n]*>/)) fail()
                closing_length=RLENGTH
                closing=substr(tail,1,closing_length)
                sub(/^[ \t\r\n]*<\//,"",closing); sub(/[ \t\r\n]*>$/,"",closing)
                if(closing!=name) fail()
                pos+=closing_length
            }
            removed++; continue
        }
        if(!depth && ++roots>1) fail()
        if(!selfclose) stack[++depth]=name
        out=out token
    }
    if(depth || roots!=1) fail()
    # 3 表示未删除节点，安装器不应仅因文件末尾换行不同生成覆盖。
    if(mode=="changed" && !removed) exit 3
    if(mode!="check") printf "%s",out
}
