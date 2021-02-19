import pandas as pd
# clean excel files that contains all the search terms for each company

search_terms_companies = pd.read_excel(r"C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter\twitter handles.xlsx")

# drop with rows are only NAs
search_terms_companies = search_terms_companies[search_terms_companies["Company"].notna()]

# company name as index
search_terms_companies = search_terms_companies.set_index("Company", drop = False)

# for each row join all non-nas to a search term separated with OR
# set up new column
search_terms_companies["search_term"] = None
for i in range(0,len(search_terms_companies)):
    
    # get all twitter handles and merge them to one search term
    terms = [k for k in search_terms_companies.iloc[i,:].tolist() if str(k) != "nan" and k != None]
    
    # account for special cases
    if "Apple" in terms:
        terms.pop(0)
    elif "Caterpillar" in terms:
        terms.pop(0)
    elif "Merck" in terms:
        terms.pop(0)
    elif "Merck1" in terms:
        terms.pop(0)
    elif "Dow" in terms:
        terms.pop(0)
    elif "Johnson & Johnson" in terms:
        terms[0] = "JohnsonJohnson"
            
    
    
    search_term_comp = ' OR '.join(terms)
    
    # store in df
    search_terms_companies.iloc[i,search_terms_companies.shape[1] - 1] = search_term_comp
    
    
# only keep search term column
search_terms_companies = search_terms_companies[["search_term"]]

#%% now adjust changes
# apple


#%%
# save as pkl
search_terms_companies.to_pickle(r"C:\Users\lukas\OneDrive - UT Cloud\Data\Twitter\search_terms_companies.pkl")