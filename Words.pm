package Words;

use Exporter 'import';

@EXPORT = qw(KW_COMPOUND KW_SIMPLE KW_LOGIC KW_BOOL KW_ERROR);

use constant KW_COMPOUND => qw(if elif else for while def);
use constant KW_SIMPLE   => qw(return break continue print in);
use constant KW_LOGIC    => qw(not and or);
use constant KW_BOOL     => qw(True False);
use constant KW_ERROR    => qw(del is raise assert from lambda global 
                       try class except import yield exec finally pass);

1;