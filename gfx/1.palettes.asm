Frame1InitialPalettes:
  dw $2A00, $0000, $7D1F, $7D1F
  dw $28A4, $7D1F, $2A00, $0000
  dw $2A00, $0000, $7D1F, $7D1F
  dw $7D1F, $7D1F, $2A00, $0000
  dw $2A00, $0000, $7D1F, $7D1F
  dw $28A4, $288F, $2A00, $0000
  dw $2A00, $0000, $28A4, $288F
  dw $28A4, $7D1F, $2A00, $0000

; Palettes diff for each scanline
Frame1PalettesDiffs:
._0
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $28A4, $288F
  dw $28A4, $288F
  dw $28A4, $7D1F
._1
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
._2
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $28A4, $288F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
._3
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $28A4
._4
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
._5
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $28A4
._6
  dw $288F, $7D1F
  dw $28A4, $288F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
._7
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
._8
  dw $288F, $28A4
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
._9
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
._10
  dw $7D1F, $7D1F
  dw $28A4, $288F
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
._11
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $28A4
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
  dw $288F, $28A4
._12
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $28A4
._13
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
._14
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $28A4
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $28A4, $288F
  dw $288F, $7D1F
  dw $288F, $7D1F
._15
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $288F
  dw $288F, $7D1F
._16
  dw $7D1F, $7D1F
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
._17
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
._18
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
  dw $288F, $28A4
  dw $28A4, $7D1F
  dw $28A4, $288F
  dw $288F, $7D1F
._19
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $28A4, $288F
._20
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $288F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
._21
  dw $28A4, $288F
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
._22
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
  dw $288F, $7D1F
._23
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $28A4
  dw $28A4, $7D1F
._24
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $28A4
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
._25
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $28A4
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
._26
  dw $28A4, $7D1F
  dw $288F, $28A4
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
._27
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
._28
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $28A4, $288F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
._29
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $28A4
  dw $288F, $28A4
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
._30
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
._31
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $28A4
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
._32
  dw $28A4, $7D1F
  dw $1D55, $28A4
  dw $288F, $28A4
  dw $1D55, $7D1F
  dw $1D55, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $288F
  dw $1D55, $28A4
._33
  dw $288F, $1D55
  dw $1D55, $7D1F
  dw $7D1F, $7D1F
  dw $1D55, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $1D55
  dw $288F, $7D1F
  dw $1D55, $28A4
._34
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $1D55, $28A4
  dw $1D55, $7D1F
  dw $1D55, $288F
  dw $1D55, $7D1F
  dw $1D55, $28A4
  dw $1D55, $7D1F
._35
  dw $1D55, $7D1F
  dw $7D1F, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $28A4
  dw $1D55, $28A4
  dw $288F, $7D1F
  dw $1D55, $288F
._36
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $1D55, $288F
  dw $28A4, $1D55
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $1D55, $288F
  dw $1D55, $7D1F
._37
  dw $1D55, $288F
  dw $288F, $1D55
  dw $1D55, $28A4
  dw $28A4, $7D1F
  dw $1D55, $28A4
  dw $28A4, $1D55
  dw $7D1F, $7D1F
  dw $1D55, $288F
._38
  dw $288F, $7D1F
  dw $28A4, $288F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $1D55, $288F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
  dw $288F, $28A4
._39
  dw $28A4, $288F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $1D55
  dw $288F, $7D1F
  dw $1D55, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $1D55
._40
  dw $1D55, $28A4
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $288F
  dw $1D55, $288F
  dw $1D55, $7D1F
  dw $28A4, $7D1F
._41
  dw $288F, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $288F
._42
  dw $1D55, $7D1F
  dw $1D55, $7D1F
  dw $28A4, $1D55
  dw $288F, $28A4
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $1D55, $7D1F
  dw $28A4, $7D1F
._43
  dw $288F, $7D1F
  dw $288F, $1D55
  dw $1D55, $288F
  dw $28A4, $7D1F
  dw $1D55, $28A4
  dw $7D1F, $7D1F
  dw $28A4, $288F
  dw $28A4, $288F
._44
  dw $1D55, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $1D55
  dw $28A4, $7D1F
  dw $7D1F, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
._45
  dw $288F, $7D1F
  dw $1D55, $28A4
  dw $1D55, $7D1F
  dw $28A4, $7D1F
  dw $1D55, $7D1F
  dw $288F, $1D55
  dw $28A4, $7D1F
  dw $28A4, $1D55
._46
  dw $1D55, $28A4
  dw $1D55, $7D1F
  dw $288F, $28A4
  dw $288F, $7D1F
  dw $288F, $28A4
  dw $28A4, $7D1F
  dw $28A4, $1D55
  dw $28A4, $7D1F
._47
  dw $1D55, $28A4
  dw $28A4, $7D1F
  dw $28A4, $288F
  dw $1D55, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $1D55
  dw $288F, $7D1F
._48
  dw $1D55, $7D1F
  dw $28A4, $288F
  dw $28A4, $7D1F
  dw $288F, $1D55
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
  dw $1D55, $7D1F
._49
  dw $288F, $7D1F
  dw $288F, $28A4
  dw $288F, $28A4
  dw $288F, $7D1F
  dw $1D55, $7D1F
  dw $288F, $1D55
  dw $28A4, $7D1F
  dw $1D55, $7D1F
._50
  dw $288F, $1D55
  dw $28A4, $288F
  dw $28A4, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $28A4
  dw $28A4, $7D1F
._51
  dw $1D55, $28A4
  dw $28A4, $7D1F
  dw $28A4, $1D55
  dw $28A4, $288F
  dw $1D55, $7D1F
  dw $7D1F, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $288F
._52
  dw $1D55, $7D1F
  dw $1D55, $28A4
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $288F, $28A4
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $1D55, $7D1F
._53
  dw $1D55, $28A4
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $1D55, $288F
  dw $7D1F, $7D1F
  dw $1D55, $28A4
  dw $28A4, $7D1F
  dw $28A4, $288F
._54
  dw $1D55, $7D1F
  dw $28A4, $7D1F
  dw $1D55, $7D1F
  dw $288F, $1D55
  dw $28A4, $288F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $288F, $28A4
._55
  dw $7D1F, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $1D55, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
._56
  dw $28A4, $1D55
  dw $1D55, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $288F
  dw $288F, $28A4
  dw $1D55, $288F
  dw $288F, $7D1F
  dw $1D55, $28A4
._57
  dw $1D55, $7D1F
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $1D55
  dw $1D55, $7D1F
  dw $1D55, $288F
  dw $28A4, $288F
  dw $1D55, $7D1F
._58
  dw $1D55, $288F
  dw $28A4, $7D1F
  dw $1D55, $288F
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $1D55, $7D1F
._59
  dw $28A4, $7D1F
  dw $288F, $7D1F
  dw $1D55, $28A4
  dw $288F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $28A4
  dw $28A4, $288F
  dw $1D55, $288F
._60
  dw $288F, $1D55
  dw $28A4, $1D55
  dw $28A4, $7D1F
  dw $288F, $1D55
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $1D55
  dw $288F, $7D1F
._61
  dw $28A4, $288F
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $1D55, $7D1F
  dw $28A4, $288F
  dw $7D1F, $7D1F
  dw $28A4, $7D1F
  dw $288F, $7D1F
._62
  dw $28A4, $1D55
  dw $288F, $28A4
  dw $288F, $28A4
  dw $28A4, $7D1F
  dw $28A4, $7D1F
  dw $1D55, $7D1F
  dw $288F, $28A4
  dw $28A4, $1D55
._63
  dw $288F, $1D55
  dw $1D55, $28A4
  dw $1D55, $28A4
  dw $1D55, $288F
  dw $28A4, $1D55
  dw $288F, $28A4
  dw $28A4, $7D1F
  dw $1D55, $7D1F
._64
  dw $212A, $7D1F
  dw $288F, $7D1F
  dw $1D55, $7D1F
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $212A
  dw $212A, $1D55
  dw $7D1F, $7D1F
._65
  dw $1D55, $288F
  dw $212A, $1D55
  dw $7D1F, $7D1F
  dw $288F, $1D55
  dw $288F, $1D55
  dw $1D55, $7D1F
  dw $288F, $7D1F
  dw $212A, $7D1F
._66
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $1D55, $7D1F
  dw $212A, $7D1F
  dw $288F, $7D1F
  dw $212A, $7D1F
  dw $1D55, $212A
  dw $288F, $1D55
._67
  dw $1D55, $288F
  dw $1D55, $7D1F
  dw $288F, $1D55
  dw $1D55, $7D1F
  dw $1D55, $7D1F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $1D55
._68
  dw $288F, $7D1F
  dw $212A, $7D1F
  dw $1D55, $212A
  dw $288F, $7D1F
  dw $212A, $7D1F
  dw $288F, $212A
  dw $288F, $7D1F
  dw $288F, $212A
._69
  dw $288F, $7D1F
  dw $212A, $1D55
  dw $212A, $1D55
  dw $212A, $7D1F
  dw $212A, $288F
  dw $288F, $212A
  dw $288F, $212A
  dw $288F, $212A
._70
  dw $1D55, $7D1F
  dw $7D1F, $7D1F
  dw $1D55, $212A
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $212A, $7D1F
._71
  dw $1D55, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $212A
  dw $288F, $212A
  dw $212A, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
._72
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $212A, $288F
  dw $288F, $212A
  dw $212A, $7D1F
  dw $212A, $1D55
  dw $7D1F, $7D1F
  dw $1D55, $7D1F
._73
  dw $288F, $7D1F
  dw $212A, $7D1F
  dw $1D55, $288F
  dw $212A, $7D1F
  dw $288F, $7D1F
  dw $212A, $7D1F
  dw $1D55, $288F
  dw $288F, $7D1F
._74
  dw $212A, $7D1F
  dw $212A, $288F
  dw $288F, $1D55
  dw $1D55, $212A
  dw $288F, $1D55
  dw $212A, $7D1F
  dw $1D55, $212A
  dw $7D1F, $7D1F
._75
  dw $1D55, $7D1F
  dw $212A, $288F
  dw $288F, $7D1F
  dw $288F, $212A
  dw $1D55, $212A
  dw $7D1F, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
._76
  dw $1D55, $288F
  dw $212A, $7D1F
  dw $288F, $7D1F
  dw $1D55, $212A
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
._77
  dw $1D55, $7D1F
  dw $288F, $1D55
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $212A, $7D1F
  dw $212A, $7D1F
  dw $7D1F, $7D1F
  dw $212A, $7D1F
._78
  dw $1D55, $7D1F
  dw $288F, $1D55
  dw $212A, $288F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
  dw $212A, $7D1F
  dw $212A, $7D1F
  dw $1D55, $7D1F
._79
  dw $288F, $1D55
  dw $1D55, $7D1F
  dw $288F, $1D55
  dw $212A, $288F
  dw $288F, $212A
  dw $1D55, $212A
  dw $288F, $7D1F
  dw $1D55, $7D1F
._80
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $288F, $7D1F
  dw $212A, $7D1F
  dw $288F, $7D1F
  dw $1D55, $7D1F
  dw $212A, $7D1F
  dw $1D55, $7D1F
._81
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $212A, $288F
  dw $212A, $1D55
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
  dw $212A, $288F
._82
  dw $212A, $7D1F
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $1D55
  dw $1D55, $288F
  dw $212A, $288F
  dw $1D55, $7D1F
  dw $212A, $7D1F
._83
  dw $212A, $1D55
  dw $212A, $1D55
  dw $1D55, $212A
  dw $212A, $288F
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $212A
  dw $212A, $7D1F
._84
  dw $212A, $7D1F
  dw $212A, $7D1F
  dw $288F, $1D55
  dw $1D55, $288F
  dw $288F, $7D1F
  dw $1D55, $7D1F
  dw $288F, $1D55
  dw $212A, $288F
._85
  dw $288F, $1D55
  dw $1D55, $7D1F
  dw $212A, $1D55
  dw $288F, $212A
  dw $1D55, $288F
  dw $212A, $288F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
._86
  dw $212A, $7D1F
  dw $212A, $7D1F
  dw $1D55, $212A
  dw $7D1F, $7D1F
  dw $288F, $7D1F
  dw $1D55, $7D1F
  dw $212A, $7D1F
  dw $1D55, $7D1F
._87
  dw $1D55, $7D1F
  dw $212A, $7D1F
  dw $212A, $7D1F
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $212A
  dw $1D55, $288F
  dw $288F, $7D1F
._88
  dw $1D55, $288F
  dw $288F, $7D1F
  dw $1D55, $7D1F
  dw $288F, $212A
  dw $288F, $212A
  dw $288F, $212A
  dw $288F, $7D1F
  dw $212A, $7D1F
._89
  dw $212A, $1D55
  dw $1D55, $288F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
  dw $212A, $1D55
  dw $1D55, $212A
  dw $212A, $7D1F
._90
  dw $1D55, $212A
  dw $288F, $7D1F
  dw $7D1F, $7D1F
  dw $288F, $7D1F
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $7D1F, $7D1F
  dw $1D55, $7D1F
._91
  dw $1D55, $7D1F
  dw $212A, $288F
  dw $7D1F, $7D1F
  dw $212A, $288F
  dw $288F, $7D1F
  dw $288F, $1D55
  dw $288F, $7D1F
  dw $288F, $1D55
._92
  dw $7D1F, $7D1F
  dw $1D55, $288F
  dw $288F, $7D1F
  dw $288F, $7D1F
  dw $212A, $7D1F
  dw $288F, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
._93
  dw $212A, $7D1F
  dw $212A, $1D55
  dw $212A, $7D1F
  dw $288F, $1D55
  dw $288F, $212A
  dw $1D55, $288F
  dw $212A, $288F
  dw $212A, $7D1F
._94
  dw $212A, $288F
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $288F, $7D1F
  dw $1D55, $288F
  dw $288F, $7D1F
  dw $1D55, $7D1F
  dw $212A, $288F
._95
  dw $7D1F, $7D1F
  dw $212A, $1D55
  dw $288F, $7D1F
  dw $212A, $288F
  dw $288F, $1D55
  dw $288F, $1D55
  dw $1D55, $7D1F
  dw $1D55, $7D1F
._96
  dw $212A, $7D1F
  dw $212A, $7D1F
  dw $212A, $6318
  dw $6318, $1D55
  dw $6318, $7D1F
  dw $6318, $212A
  dw $1D55, $7D1F
  dw $212A, $7D1F
._97
  dw $1D55, $212A
  dw $6318, $7D1F
  dw $1D55, $212A
  dw $1D55, $6318
  dw $212A, $7D1F
  dw $1D55, $6318
  dw $212A, $6318
  dw $1D55, $212A
._98
  dw $212A, $7D1F
  dw $212A, $7D1F
  dw $212A, $7D1F
  dw $1D55, $6318
  dw $6318, $7D1F
  dw $6318, $1D55
  dw $6318, $7D1F
  dw $6318, $7D1F
._99
  dw $1D55, $7D1F
  dw $6318, $7D1F
  dw $212A, $6318
  dw $212A, $6318
  dw $6318, $7D1F
  dw $6318, $7D1F
  dw $6318, $7D1F
  dw $212A, $7D1F
._100
  dw $6318, $1D55
  dw $6318, $7D1F
  dw $212A, $1D55
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $6318, $7D1F
  dw $6318, $7D1F
  dw $1D55, $212A
._101
  dw $6318, $7D1F
  dw $212A, $6318
  dw $7D1F, $7D1F
  dw $1D55, $6318
  dw $6318, $7D1F
  dw $1D55, $7D1F
  dw $6318, $1D55
  dw $212A, $7D1F
._102
  dw $212A, $1D55
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $212A
  dw $212A, $1D55
  dw $1D55, $7D1F
  dw $212A, $6318
._103
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $6318, $212A
  dw $1D55, $6318
  dw $7D1F, $7D1F
  dw $212A, $7D1F
  dw $1D55, $212A
  dw $6318, $212A
._104
  dw $1D55, $7D1F
  dw $1D55, $6318
  dw $212A, $1D55
  dw $1D55, $212A
  dw $7D1F, $7D1F
  dw $6318, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
._105
  dw $6318, $7D1F
  dw $212A, $7D1F
  dw $6318, $7D1F
  dw $212A, $7D1F
  dw $7D1F, $7D1F
  dw $1D55, $212A
  dw $6318, $1D55
  dw $1D55, $7D1F
._106
  dw $6318, $212A
  dw $6318, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $6318
  dw $1D55, $6318
  dw $6318, $1D55
  dw $1D55, $7D1F
  dw $6318, $7D1F
._107
  dw $212A, $7D1F
  dw $1D55, $6318
  dw $1D55, $7D1F
  dw $6318, $7D1F
  dw $6318, $212A
  dw $1D55, $6318
  dw $6318, $7D1F
  dw $1D55, $7D1F
._108
  dw $1D55, $7D1F
  dw $212A, $7D1F
  dw $6318, $212A
  dw $6318, $7D1F
  dw $6318, $7D1F
  dw $6318, $1D55
  dw $1D55, $7D1F
  dw $212A, $7D1F
._109
  dw $6318, $1D55
  dw $6318, $7D1F
  dw $6318, $7D1F
  dw $1D55, $7D1F
  dw $212A, $1D55
  dw $212A, $7D1F
  dw $212A, $7D1F
  dw $212A, $1D55
._110
  dw $1D55, $7D1F
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $6318, $212A
  dw $7D1F, $7D1F
  dw $212A, $7D1F
._111
  dw $212A, $6318
  dw $6318, $7D1F
  dw $1D55, $7D1F
  dw $212A, $7D1F
  dw $6318, $7D1F
  dw $6318, $7D1F
  dw $1D55, $212A
  dw $212A, $7D1F
._112
  dw $6318, $7D1F
  dw $212A, $1D55
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $212A, $1D55
  dw $7D1F, $7D1F
  dw $212A, $6318
  dw $212A, $7D1F
._113
  dw $1D55, $7D1F
  dw $212A, $7D1F
  dw $6318, $1D55
  dw $6318, $212A
  dw $6318, $212A
  dw $212A, $6318
  dw $6318, $7D1F
  dw $7D1F, $7D1F
._114
  dw $6318, $1D55
  dw $6318, $212A
  dw $212A, $7D1F
  dw $212A, $7D1F
  dw $7D1F, $7D1F
  dw $1D55, $7D1F
  dw $212A, $6318
  dw $212A, $7D1F
._115
  dw $6318, $7D1F
  dw $6318, $7D1F
  dw $6318, $212A
  dw $7D1F, $7D1F
  dw $1D55, $7D1F
  dw $212A, $7D1F
  dw $7D1F, $7D1F
  dw $1D55, $7D1F
._116
  dw $1D55, $6318
  dw $212A, $6318
  dw $1D55, $6318
  dw $1D55, $6318
  dw $1D55, $7D1F
  dw $6318, $7D1F
  dw $212A, $7D1F
  dw $6318, $7D1F
._117
  dw $212A, $1D55
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $7D1F, $7D1F
  dw $1D55, $7D1F
  dw $212A, $6318
  dw $1D55, $7D1F
  dw $1D55, $7D1F
._118
  dw $1D55, $7D1F
  dw $7D1F, $7D1F
  dw $212A, $1D55
  dw $212A, $6318
  dw $212A, $7D1F
  dw $212A, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
._119
  dw $212A, $6318
  dw $6318, $7D1F
  dw $212A, $7D1F
  dw $212A, $7D1F
  dw $1D55, $212A
  dw $6318, $7D1F
  dw $1D55, $7D1F
  dw $7D1F, $7D1F
._120
  dw $212A, $7D1F
  dw $1D55, $6318
  dw $6318, $212A
  dw $1D55, $7D1F
  dw $6318, $212A
  dw $1D55, $7D1F
  dw $7D1F, $7D1F
  dw $1D55, $212A
._121
  dw $212A, $6318
  dw $6318, $7D1F
  dw $7D1F, $7D1F
  dw $7D1F, $7D1F
  dw $6318, $212A
  dw $6318, $7D1F
  dw $1D55, $7D1F
  dw $1D55, $7D1F
._122
  dw $6318, $7D1F
  dw $1D55, $7D1F
  dw $212A, $7D1F
  dw $1D55, $212A
  dw $6318, $212A
  dw $212A, $7D1F
  dw $7D1F, $7D1F
  dw $1D55, $7D1F
._123
  dw $1D55, $212A
  dw $212A, $7D1F
  dw $212A, $7D1F
  dw $1D55, $212A
  dw $1D55, $7D1F
  dw $1D55, $6318
  dw $212A, $7D1F
  dw $1D55, $7D1F
._124
  dw $6318, $212A
  dw $1D55, $7D1F
  dw $212A, $6318
  dw $212A, $1D55
  dw $1D55, $7D1F
  dw $7D1F, $7D1F
  dw $212A, $1D55
  dw $1D55, $212A
._125
  dw $6318, $212A
  dw $6318, $1D55
  dw $212A, $6318
  dw $1D55, $7D1F
  dw $6318, $7D1F
  dw $212A, $6318
  dw $6318, $1D55
  dw $7D1F, $7D1F
._126
  dw $1D55, $7D1F
  dw $1D55, $7D1F
  dw $6318, $7D1F
  dw $7D1F, $7D1F
  dw $6318, $7D1F
  dw $212A, $1D55
  dw $6318, $7D1F
  dw $212A, $7D1F
._127
  dw $1D55, $7D1F
  dw $7D1F, $7D1F
  dw $1D55, $7D1F
  dw $212A, $1D55
  dw $6318, $212A
  dw $212A, $7D1F
  dw $6318, $7D1F
  dw $6318, $1D55
