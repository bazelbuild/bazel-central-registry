## Notes to help generating patch files

To create the no_contrib.patch file, run the following commands:

```
rg -l behaviortree_cpp/contrib/json.hpp | xargs sed -i -e 's;behaviortree_cpp/contrib/json.hpp;nlohmann/json.hpp;g'
```

```
rg -l behaviortree_cpp/contrib/magic_enum.hpp | xargs sed -i -e 's;behaviortree_cpp/contrib/magic_enum.hpp;magic_enum/magic_enum.hpp;g'
```


