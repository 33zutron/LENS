local s = import 'lib_lens.jsonnet';

s.basic_rule('go', 
             s.And('os.Mkdir($NAME, $PERM)',
                   s.Where('$PERM > 0o600')))

