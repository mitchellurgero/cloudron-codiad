<?php

/*
 * Codiad LDAP External Authentication Bridge
 *
 * Copyright (C) 2015 Matt Schultz (Korynkai) & QuantuMatriX Technologies (qmxtech.com)
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

///////////////////
// CONFIGURATION //
///////////////////

// The LDAP connection URI of the server.
	$server = getenv('LDAP_URL');

// The DN to search under on the server.
	$basedn = getenv('LDAP_USERS_BASE_DN');

// Use anonymous bind
//  This does not work by default on Active Directory, however this is the 
//  default method for most servers based on the LDAP standard.
//    Optionally one can bind to a user for search on any LDAP server or
//    enable anonymous binds for search on Active Directory, however this
//    allows for any search option.
	$anonbind = false;
    
// LDAP User for bind (if anonymous bind is set to "false").
	$binddn = getenv('LDAP_BIND_DN');
	$bindpass = getenv('LDAP_BIND_PASSWORD');

// The LDAP search filter. If you aren't sure what this is, the official
// IETF RFC definition (quite technical) is here: 
//	http://tools.ietf.org/search/rfc4515
// and you can find another good (easier to follow) reference here
// (shortened CentOS documentation link):
//	http://goo.gl/FOdGp7
// The default will allow a CN or an email to log in (however, the user 
// environments between the CN and email logins would differ).
// Default is: '(&(objectClass=*)(|(cn=$1)(email=$1)))'.
// A couple alternatives for simple set-ups: 
//	CN only: '(&(objectClass=*)(cn=$1))'
//	email only: '(&(objectClass=*)(email=$1))'
	//$filter = "(&(objectClass=*)(|(cn=$1)(email=$1)))";
        $filter = '(&(objectclass=user)(|(username=1)(mail=1)))';
// Optionally create Codiad user if it doesn't already exist. This can be set
// to 'false' if the administrator would like to manually control access to 
// Codiad from within Codiad itself, rather than let the search filter fully
// dictate user access control. 
// 	Default is 'true'.
	$createuser = true;

// The LDAP protocol version to use. Changing this is probably a very bad 
// idea unless you're absolutely positive you are using some completely 
// non-standard or obsolete (pre-2003) version of LDAP.
// 	Default is '3'. Developer heavily discourages changing this.
	$version = 3;

/////////////////////////////////////////////////////////////////////////////
// DO NOT EDIT ANYTHING UNDER THIS LINE UNLESS YOU KNOW WHAT YOU'RE DOING! //
/////////////////////////////////////////////////////////////////////////////
	//include(__DIR__."/config.php");
	// Ensure we have class.user.php so we may use this class.
	require_once( COMPONENTS . "/user/class.user.php" );
    $preauth = '';
	// Check if our session is not logged in.
	if ( !isset( $_SESSION['user'] ) ) {

		// Check if a username and password were posted.
		if ( isset( $_POST['username'] ) && isset( $_POST['password'] ) ) {

			// Create user object.
			$User = new User();

			// Initialize values of user object.
			$User->username = $_POST['username'];
			$User->password = $_POST['password'];

			// Replace user name token in search filter.
			$tfilter = str_replace( "1", $User->username, $filter );

			// Create LDAP connection socket.
			$socket = ldap_connect( $server );

			// Set initial LDAP values.
			ldap_set_option( $socket, LDAP_OPT_PROTOCOL_VERSION, $version );
			ldap_set_option( $socket, LDAP_OPT_REFERRALS, 0 );
			
			// Check if we are using anonymous bind.
			if ( $anonbind == true ) {
			
				// Set preauth flag to value of socket on anonymous bind.
				$preauth = $socket;
			
			} else {
				
				// Set preauth flag using call to ldap_bind on authenticated bind.
				$preauth = ldap_bind( $socket, $binddn, $bindpass );
			
			}

			// Check if LDAP pre-authentication (or socket creation) was a success.
			if ( $preauth == true ) {

				// Search through basedn based on the filter, and count entries.
				$result = ldap_search( $socket, $basedn, $tfilter );
				$count  = ldap_count_entries( $socket, $result );
					var_error_log($count);
				// Ensure count is definitely equal to 1
				if ( $count === 1 ) {

					// Get the entry from the search result, and bind using its DN.
					$data = ldap_get_entries( $socket, $result );
					$auth = ldap_bind( $socket, $data[0]['dn'], $User->password );
					
					// Check the return value of the bind action.
					if ( $auth === -1 ) {

						// Deny login and send message, An LDAP error occurred.
						die( formatJSEND( "error", "An LDAP error has occurred: " . ldap_error($socket) ) );

					} elseif ( $auth == false ) {

						// Invalid login.
						die( formatJSEND( "error", "Invalid user name or password." ) );

					} elseif ( $auth == true ) {

						// Check if user already exists within users.php.
						if ( $User->CheckDuplicate() ) {

							// Check if we can create a user within users.php.
							if ( $createuser == true ) {

							// Save array back to JSON and set the session username.
							$User->users[] = array( 'username' => $User->username, 'password' => null, 'project' => "" );
							saveJSON( "users.php", $User->users );
							$_SESSION['user'] = $User->username;

							} else {

								// Deny login and send message, the user doesn't exist within users.php.
								die( formatJSEND( "error", "User " . $User->username . " does not exist within Codiad." ) );

							}

						} else {

							// Set the session username.
							$_SESSION['user'] = $User->username;

						}

						// Set the session language, if given, or set it to english as default.
						if ( isset( $_POST['language'] ) ) {

							$_SESSION['lang'] = $_POST['language'];

						} else {

							$_SESSION['lang'] = "en";

						}

						// Set the session theme and project.
						$_SESSION['theme'] = $_POST['theme'];
						$_SESSION['project'] = $_POST['project'];

						// Respond by sending verification tokens on success.
						echo formatJSEND( "success", array( 'username' => $User->username ) );
						header( "Location: " . $_SERVER['PHP_SELF'] . "?action=verify" );

					}

				} elseif ( $count > 1 ) {

					// We returned too many results. Error as such.
					die( formatJSEND( "error", "A server error occurred: LDAP filter result is non-unique. Please ensure this is a unique identifier within its context.
												If the problem persists, please contact the webmaster. If you are the webmaster, please check the LDAP filter used." ) );

				} else {

					// Invalid login.
					//var_error_log($auth);
					die( formatJSEND( "error-ldap", "Incorrect user name or password." ) );

				}

			} else {

				// The server is having issues connecting to the LDAP server. Error as such.
				die( formatJSEND( "error", "An error occurred: Cannot connect to LDAP server. Please contact the webmaster. 
											If you are the webmaster, please contact your LDAP server administrator or check if your LDAP server is running." ) );

			}
		}
	}
function var_error_log( $object=null ){
    ob_start();                    // start buffer capture
    var_dump( $object );           // dump the values
    $contents = ob_get_contents(); // put the buffer into a variable
    ob_end_clean();                // end capture
    error_log( $contents );        // log contents of the result of var_dump( $object )
}
?>

