@rem SPDX-FileCopyrightText: 2019 Antonio Villena <_@antoniovillena.es>
@rem
@rem SPDX-FileContributor: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
@rem
@rem SPDX-License-Identifier: GPL-3.0-only
copy /Y FLASHempty.ZX1 FLASH.ZX1
call addroms.bat
call addcores.bat
