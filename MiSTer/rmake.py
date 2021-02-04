#!/usr/bin/env python
import runpy, sys
sys.argv.append('--root=.')
sys.argv.append('--core=atarisys1')
sys.argv.append('--top=tb_atarisys1')
runpy.run_path('../../replay_common/scripts/common.py')