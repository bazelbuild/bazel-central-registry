"""utils for the BUILD files.
"""

def get_repo_name():
    return Label("//:BUILD.bazel").workspace_name

def remove_extra_chars(str):
    return str.replace(")", "").replace(";", "").replace("\r", "")

def parse_perlasm_gen(perlasm_gen):
    """Take a perlasm gen string and parse it.

    Args:
        perlasm_gen: The perlasm generation string
    Returns:
        Two dictionaries. The first has the keys and values that are not dupes or the first instances of dupes.
        The second has the remaining keys and values that are dupes. Keys are tools and values are outs.
    """
    perlasm_outs = []
    perlasm_tools = []

    perlasm_gen_split_by_line = perlasm_gen.split("\n")
    for line in perlasm_gen_split_by_line:
        split_by_space = line.split(" ")

        # When you split by new line you get an empty string at points.
        if not split_by_space:
            continue
        elif not split_by_space[0]:
            continue
            # On arm we get carriage returns

        elif split_by_space[0] == "\r\r":
            continue
        elif len(split_by_space) != 6:
            fail("Line {} not six parts".format(line))
        tool = fix_path_for_windows_in_str(remove_extra_chars(split_by_space[2]))
        out = fix_path_for_windows_in_str(remove_extra_chars(split_by_space[5]))
        perlasm_tools.append(tool)
        perlasm_outs.append(out)

    return dedupe_and_ret_dicts(perlasm_tools, perlasm_outs)

def dedupe_and_ret_dicts(lst_one, lst_two):
    """Dedupe a list and make two dictionaries with that and another list

    Args:
        lst_one: First list. We dedupe this and use as keys.
        lst_two: Second list. We don't dedupe this and use as values.
    Returns:
        Two dictionaries. The first has the keys and values that are not dupes or the first instances of dupes.
        The second has the remaining keys and values that are dupes.
    """
    if len(lst_one) != len(lst_two):
        fail("Lists are not the same length: {} with len {} and {} with len {}".format(lst_one, len(lst_one), lst_two, len(lst_two)))
    dict_one = {}
    dict_two = {}

    for i in range(len(lst_one)):
        one_i = lst_one[i]
        two_i = lst_two[i]
        if one_i in dict_one.keys():
            if one_i in dict_two.keys():
                pass
            else:
                dict_two[one_i] = two_i
        else:
            dict_one[one_i] = two_i
    return dict_one, dict_two

def dedupe(lst):
    """Dedupe a list

    Args:
        lst: A list of things
    Returns:
        The deuped list.
    """
    final_lst = []
    for thing in lst:
        if thing in final_lst:
            continue
        else:
            final_lst.append(thing)

    return final_lst

def fix_paths_for_windows(path_lst):
    """Replace the \\ with / on Windows.

        We need them to be the opposite way when writing the generated bzl files on Windows.
        But when we use the files we need to fix the paths.
        Args:
            path_lst: The list of paths to fix.
        Return:
            The fixed path list.
    """
    return [fix_path_for_windows_in_str(path) for path in path_lst]

def fix_path_for_windows_in_str(str):
    """Replace the \\ with / on Windows.

        We need them to be the opposite way when writing the generated bzl files on Windows.
        But when we use the files we need to fix the paths.
        Args:
            str: The string to fix.
        Return:
            The fixed string.
    """
    return str.replace("\\", "/")

def remove_dupes(lst_one, lst_two):
    """Remove dupes from list one that exist in list two

    Args:
        lst_one: The first list
        lst_two: The second list
    Returns:
        list one without dupes
    """
    return [item for item in lst_one if item not in lst_two]
