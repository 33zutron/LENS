<?php
// https://lens.dev/s/idawson-gl:findmethod
// from https://github.com/returntocorp/lens/issues/4589
class SomeClass extends \SomePkg\SomeBase
{
    public function someMethod(\SomePkg\Other $var)
    {
        return null;
    }
}
?>
