#first load the newest v2 data
import os
os.system("/home/ubuntu/anaconda3/envs/numerai/bin/python3 /home/ubuntu/numerai/v2_load.py")

globals().clear()
locals().clear()
import gc
gc.collect()

#first load the newest v3 data
import os
os.system("/home/ubuntu/anaconda3/envs/numerai/bin/python3 /home/ubuntu/numerai/v3_load.py")

globals().clear()
locals().clear()
import gc
gc.collect()

#first load the newest v4 data
import os
os.system("/home/ubuntu/anaconda3/envs/numerai/bin/python3 /home/ubuntu/numerai/v4_load.py")

globals().clear()
locals().clear()
import gc
gc.collect()


#v4 small model predictions
import os
os.system("/home/ubuntu/anaconda3/envs/numerai/bin/python3 /home/ubuntu/numerai/v4_smallfeatures.py")

globals().clear()
locals().clear()
import gc
gc.collect()

