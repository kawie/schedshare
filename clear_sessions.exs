alias Schedshare.{Accounts, Repo}; user = Accounts.get_user_by_email("post@kai.gs"); Repo.delete_all(Schedshare.Accounts.UserToken)
