cad0    defb    'Core:             ',0
      IF version=1
cad1    defb    'http://zxuno.speccy.org', 0
      ELSE
cad1    defb    'http://zxdos.forofpga.es', 0
      ENDIF
        defb    'ZX-Uno BIOS v0.76', 0
        defb    'Copyleft ', 127, ' 2018 ZX-Uno Team', 0
        defb    'Processor: Z80 3.5MHz', 0
        defb    'Memory:    '
cadmem  defb    '512K Ok', 0
        defb    'Graphics:  normal, hi-color', 0
        defb    'hi-res, ULAplus', 0
        defb    'Booting:', 0
      IF  vertical=0
        defb    'Press <Edit> to Setup    <Break> Boot Menu', 0
cad2    defb    $12, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $13, 0
        defb    $10, '   Please select boot machine:    ', $10, 0
cad3    defb    $16, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $17, 0
cad4    defb    $10, '                                  ', $10, 0
cad5    defb    $10, '    ', $1c, ' and ', $1d, ' to move selection     ', $10, 0
        defb    $10, '   ENTER to select boot machine   ', $10, 0
        defb    $14, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $15, 0
cad118  defb    '        Please select boot machine', 0
cad6    defb    'Enter Setup', 0
cad7    defb    ' Main  ROMs  Upgrade  Boot  Advanced  Exit', 0
        defb    $12, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $19, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $13, 0
cad8    defb    $10, '                         ', $10, '              ', $10, 0
        defb    $10, 0
cad9    defb    $14, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $18, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $15, 0
        defb    '   BIOS v0.76    ', $7f, '2018 ZX-Uno Team', 0
      ELSE
        defb    'Press <Edit> to Setup',0
        defb    '      <Break> Boot Menu', 0
cad2    defb    $12
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $13, 0
        defb    $10, '  Select boot machine:    ', $10, 0
cad3    defb    $16
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $17, 0
cad4    defb    $10, '                          ', $10, 0
cad5    defb    $10, '    ', $1c, ' and ', $1d, ' to move       ', $10, 0
        defb    $10, '   ENTER to select boot   ', $10, 0
        defb    $14
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $15, 0
cad118  defb    '        Please select boot machine', 0
cad6    defb    'Enter Setup', 0
cad7    defb    ' Main ROMs Upgr Boot Advan Exit', 0
        defb    $12, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $13, 0
cad8    defb    $10, '                              ', $10, 0
        defb    $10, 0
cad9    defb    $14, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $15, 0
        defb    ' BIOS v0.76 ', $7f, '2018 ZX1 Team', 0
        defs    $66
      ENDIF
cad10   defb    'Hardware tests', 0
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, 0
        defb    $1b, ' Memory test', 0
        defb    $1b, ' Sound test', 0
        defb    $1b, ' Tape test', 0
        defb    $1b, ' Input test', 0
        defb    ' ', 0
        defb    'Options', 0
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11, 0
        defb    'Quiet Boot', 0
        defb    'Check CRC', 0
        defb    'Keyboard', 0
        defb    'Timing', 0
        defb    'Contended', 0
        defb    'DivMMC', 0
        defb    'NMI-DivMMC', 0
        defb    'New G.Modes', 0, 0
cad11   defb    ' ', $10, 0
        defb    ' ', $10, 0
        defb    ' ', $10, 0
        defb    ' ', $10, 0
        defb    ' ', $10, 0
        defb    ' ', $16, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $17, 0
        defb    ' ', $10, 0
        defb    ' ', $10, 0
        defb    ' ', $10, 0
        defb    ' ', $10, 0
        defb    ' ', $10, 0
        defb    ' ', $10, 0
        defb    ' ', $10, 0
        defb    ' ', $10, 0, 0
cad12   defb    'Name               Slot', 0
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, 0
        defb    $11, $11, $11, $11, 0
cad13   defb    $1e, ' ', $1f, ' Sel.Screen', 0
        defb    $1c, ' ', $1d, ' Sel.Item', 0
        defb    'Enter Change', 0
        defb    'Graph Save&Exi', 0
        defb    'Break Exit', 0
        defb    'N   New Entry', 0
cad14   defb    'Run a diagnos-', 0
        defb    'tic test on', 0
        defb    'your system', 0
        defb    'memory', 0, 0
cad15   defb    'Performs a', 0
        defb    'sound test on', 0
        defb    'your system', 0, 0
cad16   defb    'Performs a', 0
        defb    'keyboard &', 0
        defb    'joystick test', 0, 0
cad17   defb    'Hide the whole', 0
        defb    'boot screen', 0
        defb    'when enabled', 0, 0
cad18   defb    'Enable RAM and', 0
        defb    'ROM on DivMMC ', 0
        defb    'interface.', 0
        defb    'Ports are', 0
        defb    'available', 0, 0
cad19   defb    'Disable for', 0
        defb    'better compa-', 0
        defb    'tibility with', 0
        defb    'SE Basic IV', 0, 0
cad20   defb    'Behaviour of', 0
        defb    'bit 6 on port', 0
        defb    '$FE depends', 0
        defb    'on hardware', 0
        defb    'issue', 0, 0
cad21   defb    $12, $11, $11, $11, ' Options ', $11, $11, $11, $13, 0
cad22   defb    $10, '               ', $10, 0
        defb    $14, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $15, 0
cad88   defb    'Spanish', 0
cad89   defb    'English', 0
cad90   defb    'Spectrum', 0
cad91   defb    'Kempston', 0
cad92   defb    'SJS1', 0
cad93   defb    'SJS2', 0
cad94   defb    'Protek', 0
cad95   defb    'Fuller', 0
cad955  defb    'OPQAspM', 0
cad96   defb    'PAL', 0
cad97   defb    'NTSC', 0
cad98   defb    'VGA', 0
cad28   defb    'Disabled', 0
cad29   defb    'Enabled', 0
cad30   defb    'Issue 2', 0
cad31   defb    'Issue 3', 0
cadv2   defb    'Auto', 0
cadv3   defb    '48K', 0
cadv4   defb    '128K', 0
cadv5   defb    'Pentagon', 0
cad32   defb    'Move Up    q', 0
cad33   defb    'Set Active', 0
cad34   defb    'Move Down  a', 0
cad35   defb    'Rename', 0
cad36   defb    'Delete', 0
      IF  vertical=0
        defb    ' ', $12, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    ' Rename ', $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $13, 0
        defb    ' ', $10, ' ', $1e, ' ', $1f, '  Enter accept  Break cancel ', $10, 0
        defb    ' ', $16, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $17, 0
        defb    ' ', $10, '                                 ', $10, 0
        defb    ' ', $14, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $15, 0
      ELSE
        defb    ' ', $12, $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    ' Rename ', $11, $11, $11, $11, $11, $11, $11, $11, $13, 0
        defb    ' ', $10, '    ', $1e, ' ', $1f, '  Enter Break     ', $10, 0
        defb    ' ', $16
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $17, 0
        defb    ' ', $10, '                         ', $10, 0
        defb    ' ', $14
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $15, 0
        defs    $28
      ENDIF
cad38   defb    'Exit system', 0
        defb    'setup after', 0
        defb    'saving the', 0
        defb    'changes', 0, 0
cad39   defb    'Exit system', 0
        defb    'setup without', 0
        defb    'saving any', 0
        defb    'changes', 0, 0
cad40   defb    'Save Changes', 0
        defb    'done so far to', 0
        defb    'any of the', 0
        defb    'setup options', 0, 0
cad41   defb    'Discard Chan-', 0
        defb    'ges done so', 0
        defb    'far to any of', 0
        defb    'the setup', 0
        defb    'options', 0, 0
cad45   defb    'Header:', 0
cad46   defb    $12, ' Exit Without Saving ', $11, $13, 0
        defb    $10, '                      ', $10, 0
        defb    $10, ' Quit without saving? ', $10, 0
cad47   defb    $12, $11, ' Save Setup Values ', $11, $11, $13, 0
        defb    $10, '                      ', $10, 0
        defb    $10, '  Save configuration? ', $10, 0
cad48   defb    $12, ' Load Previous Values ', $13, 0
        defb    $10, '                      ', $10, 0
        defb    $10, ' Load previous values?', $10, 0
cad42   defb    $10, '                      ', $10, 0
        defb    $16, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $17, 0
        defb    $10, '      Yes     No      ', $10, 0
cad43   defb    $14, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $15, 0
        defb    $12, $11, $11, $11, ' Save and Exit ', $11, $11, $11, $11, $13, 0
        defb    $10, '                      ', $10, 0
        defb    $10, '  Save conf. & Exit?  ', $10, 0
cad44   defb    $12, $11, $11, $11, ' Load from tape ', $11, $11, $11, $13, 0
cad445  defb    $12, $11, $11, $11, $11, ' Load from SD ', $11, $11, $11, $11, $13, 0
        defb    $10, '                      ', $10, 0
        defb    $10, ' Are you sure?        ', $10, 0
cad37   defb    'Save Changes & Exit', 0
        defb    'Discard Changes & Exit', 0
        defb    'Save Changes', 0
        defb    'Discard Changes', 0
cad49   defb    'Press play on', 0
        defb    'tape & follow', 0
        defb    'the progress', 0
        defb    'Break to', 0
        defb    'cancel', 0, 0
cad50   defb    'Loading Error', 0
cad51   defb    'Any key to return', 0
cad52   defb    'Block 1 of 1:', 0
cad53   defb    'Done', 0
cad54   defb    'Slot position:', 0
cad55   defb    'Invalid CRC in ROM 0000. Must be 0000', 0
        defb    'Press any key to continue                 ', 0
cad56   defb    'Check CRC in', 0
        defb    'all ROMs. Slow', 0
        defb    'but safer', 0, 0
cad57   defb    'Machine upgraded', 0
cad58   defb    'BIOS upgraded', 0
cad59   defb    'ESXDOS upgraded', 0
cad60   defb    'Upgrade ESXDOS for ZX', 0
cad61   defb    'Upgrade BIOS for ZX', 0
cad615  defb    'Upgrade flash from SD', 0
cad62   defb    'ZX Spectrum', 0
cad63   defb    'Status:[           ]', 0
cad64   defb    ' ', $12, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    ' Recovery ', $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $11, $13, 0
        defb    ' ', $10, ' ', $1e, ' ', $1f, '  Enter accept  Break cancel ', $10, 0
        defb    ' ', $16, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $17, 0
        defb    ' ', $10, 'Name                             ', $10, 0
        defb    ' ', $10, '                                 ', $10, 0
        defb    ' ', $10, 'Slt Siz Bnk Siz p1F p7F Flags    ', $10, 0
        defb    ' ', $10, '                                 ', $10, 0
        defb    ' ', $14, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11
        defb    $11, $11, $11, $11, $11, $11, $11, $15, 0, 0
cad65   defb    'Performing...', 0
cad66   defb    '                       ', 0
cad67   defb    ' OK', 0
cad68   defb    ' Er', 0
cad69   defb    '00', 0
cad70   defb    'Set timings', 0
        defb    '224T if 48K', 0
        defb    '228T if 128K', 0, 0
cad71   defb    'Memory usually', 0
        defb    'contended.', 0
        defb    'Disabled on', 0
        defb    'Pentagon 128K', 0, 0
cad72   defb    'Performs a', 0
        defb    'tape test', 0, 0
cad74   defb    'Kempston', 0
        defb    'Break key to return', 0
        defb             '234567890'
        defb    'Q'+$80, 'WERTYUIOP'
        defb    'A'+$80, 'SDFGHJKLe'
        defb    'c'+$80, 'ZXCVBNMsb'
        defb    'o'+$80, $1c, $1d, $1e, $1f, $80
cad75   defb    'Insert SD with', 0
        defb    'the file on', 0
        defb    'root', 0, 0
cad76   defb    'Be quiet, avoid brick', 0
cad77   defb    'SD or partition error', 0
cad78   defb    'Not found or bad size', 0
cad785  defb    'Status:[ooooooooooo]', 0
cad79   defb    ' Successfully burned ', 0
cad80   defb    'EAR input', 0
cad81   defb    'SD file', 0
cad82   defb    'Input machine\'s name', 0
      IF version=2
files   defb    'ESXDOS  ZX', LX16
        defb    'FIRMWAREZX', LX16
        defb    'FLASH   ZX', LX16
        defb    'SPECTRUMZX', LX16
fileco  defb    'CORE    ZX', LX16
      ELSE
files   defb    'ESXDOS  ZX', $30+version
        defb    'FIRMWAREZX', $30+version
        defb    'FLASH   ZX', $30+version
        defb    'SPECTRUMZX', $30+version
fileco  defb    'CORE    ZX', $30+version
      ENDIF
cad83   defb    'Input', 0
        defb    $11, $11, $11, $11, $11, $11, $11, $11, 0
        defb    'Keyb Layout', 0
        defb    'Joy Keypad', 0
        defb    'Joy DB9', 0
        defb    ' ', 0
        defb    ' ', 0
        defb    'Output', 0
        defb    $11, $11, $11, $11, $11, $11, $11, $11, $11, 0
        defb    'Video', 0
        defb    'Scanlines', 0
        defb    'Frequency', 0
        defb    'CPU Speed', 0
        defb    'CSync', 0, 0
cad84   defb    'Select PS/2', 0
        defb    'mapping to', 0
        defb    'spectrum', 0, 0
cad85   defb    'Simulated', 0
        defb    'joystick', 0
        defb    'configuration', 0, 0
cad86   defb    'Real joystick', 0
        defb    'configuration', 0, 0
cad87   defb    'Select '
cad875  defb    'Default', 0
        defb    'video output', 0, 0
cad99   defb    'Enable VGA', 0
        defb    'scanlines', 0, 0
cad100  defb    'Set VGA', 0
        defb    'horizontal',0
        defb    'frequency', 0, 0
cad101  defb    'Set CPU', 0
        defb    'speed', 0, 0
cad10a  defb    'CSync method', 0
        defb    'to use', 0, 0
cad102  defb    '50', 0
cad103  defb    '51', 0
cad104  defb    '53.5', 0
cad105  defb    '55.8', 0
cad106  defb    '57.4', 0
cad107  defb    '59.5', 0
cad108  defb    '61.8', 0
cad109  defb    '63.8', 0
cad110  defb    '1X', 0
cad111  defb    '2X', 0
cad112  defb    '4X', 0
cad113  defb    '8X', 0
cad114  defb    'Break to exit', 0
cad115  defb    'Slot occupied, select', 0
        defb    'another or delete a', 0
        defb    'ROM to free it', 0
cad116  defb    'Disable for', 0
        defb    'better compa-', 0
        defb    'tibility with', 0
        defb    'old games', 0, 0
cad117  defb    'Remove jumpers', 0
        defb    'to continue', 0, 0
cad119  defb    ' Add new core', 0

;cad199  defb    'af0000 bc0000 de0000 hl0000 sp0000 ix0000 iy0000', 0

fincad
