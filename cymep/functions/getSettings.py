import json

def load_settings_from_json(filename):
    # Load user settings from a json file
    with open(filename) as config_file:
        user_settings = json.load(config_file).get("CyMeP")

    # Check settings types
    setting_type = {
    "basin": int,
    "csvfilename": str,
    "gridsize": (int,float),
    "styr": int,
    "enyr": int,
    "stmon": int,
    "enmon": int,
    "truncate_years": bool,
    "THRESHOLD_ACE_WIND": (int,float),
    "THRESHOLD_PACE_PRES": (int,float),
    "do_special_filter_obs": bool,
    "do_fill_missing_pw": bool,
    "do_defineMIbypres": bool}

    for setting in user_settings:
      stype = setting_type[setting]
      if not isinstance(user_settings[setting], stype):
        raise TypeError("Setting " + setting + " must be of type " + str(stype))

    return user_settings
