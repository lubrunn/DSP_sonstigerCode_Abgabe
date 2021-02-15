def date_finder(files):
    
    import os
    import re
    from datetime import datetime
    import numpy as np
    import pandas as pd
    
    # extract date from file names
    dates = [re.search(r'\d{4}-\d{2}-\d{2}', file).group() for file in files]
    
    # convert to dates
    dates_list = [datetime.strptime(date, "%Y-%m-%d").date() for date in np.array(dates)]
    
    # find last date
    last_date = max(dates_list)
    
    # find first date
    first_date = min(dates_list)
    
    # create a range of dates, which are used to loop thorugh the json files
    date_range_input = pd.date_range(start=first_date,end=last_date)
    
    return date_range_input