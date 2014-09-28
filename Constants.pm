#
#  Constants.pm
#  Imports commonly used constants.
#
#  Created by Alen Bou-Haidar on 26/09/14, edited 26/9/14
#

package Constants;

use Exporter 'import';

@EXPORT = qw(TRUE FALSE OPERATION);

use constant TRUE   => 1;
use constant FALSE  => 0;

use constant OPERATION => qw(BITWISE ARITHMETIC COMPARISON IN LOGICAL);
1;