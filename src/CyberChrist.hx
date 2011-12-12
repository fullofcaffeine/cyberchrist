
import neko.Lib;
import neko.Sys;
import neko.FileSystem;
import neko.io.File;
import haxe.Template;

using StringTools;

/*
private typedef Site = {
	var title : String;
	var content : String;
}
*/

private typedef PostDate = {
	var year : String;
	var month : String;
	var day : String;
}

private typedef Post = {
	var id : String;
	var title : String;
	var content : String;
	var date : PostDate;
	var path : String;
	//var layout : String;
}

/**
	Template fucker.
*/
class CyberChrist {
	
	public static var VERSION = "0.2.1";
	
	static var e_site = ~/ *---(.+) *--- *(.+)/ms;
	static var e_header_line = ~/^ *([a-zA-Z0-9_\/\.\-]+) *: *([a-zA-Z0-9!_,\/\.\-\?\(\)\s]+) *$/;
	static var e_post_filename = ~/^([0-9][0-9][0-9][0-9])-([0-9][0-9])-([0-9][0-9])-([a-zA-Z0-9_,!\.\-\?\(\)\+]+)$/;
	
	static var path_src : String;
	static var path_dst : String;
	static var tpl_site : Template;
	static var posts : Array<Post>;
	static var panda : panda.Format;
	
	
	// ----- SYSTEM -----
	
	static inline function println( t : String ) Lib.println(t)
	static function warn( t : String ) println( "Warning! "+t )
	
	static function writeFile( path : String, t : String ) {
		var f = File.write( path, false );
		f.writeString( t );
		f.close();
	}
	
	static function wipeDirectory( path : String ) {
		for( f in FileSystem.readDirectory( path ) ) {
			var p = path+"/"+f;
			switch( FileSystem.kind( p ) ) {
			case kdir :
				wipeDirectory( p );
				FileSystem.deleteDirectory( p );
			case kfile :	
				FileSystem.deleteFile( p );
			default :
			}
		}
	}
	
	static function copyDataDirectory( path : String ) {
		var ps = path_src+path;
		for( f in FileSystem.readDirectory( ps ) ) {
			var s = ps+"/"+f;
			var d = path_dst+path+"/"+f;
			switch( FileSystem.kind( s ) ) {
			case kdir :
				if( !FileSystem.exists(d) )
					FileSystem.createDirectory( d );
				copyDataDirectory( path+"/"+f );
			case kfile :
				File.copy( s, d );
			default:
			}
		}
	}
	
	
	// ----- PROCESSING -----
	
	static function parseSite( path : String, name : String ) : Dynamic {
		//trace( "Parsing site: "+path+"/"+name );
		var fp = path+"/"+name;
		var ft = File.getContent( fp );
		if( !e_site.match( ft ) )
			error( "invalid html template ("+fp+")" );
		var header : Dynamic = {};
		for( l in e_site.matched(1).trim().split("\n") ) {
			if( ( l = l.trim() ) == "" )
				continue;
			if( !e_header_line.match( l ) )
				error( "invalid template header ("+l+")" );
			var id = e_header_line.matched(1);
			var v = e_header_line.matched(2);
			switch( id ) {
			case "title": header.title = v;
			case "layout": header.layout = v;
			case "tags":
				var r = ~/( *, *)/g;
				if( !r.match( v ) ) {
					warn( "invalid syntax for header tags: "+v );
					continue;
				}
				header.tags = r.split(  v );
			default :
				trace( "unknown header key ("+id+")" );
			}
		}
		var r = header;
		r.content = e_site.matched(2);
		return r;
	}
	
	static function processDirectory( path : String ) {
		for( f in FileSystem.readDirectory( path ) ) {
			if( f.startsWith(".") )
				continue;
			var fp = path+f;
			switch( FileSystem.kind( fp ) ) {
			case kfile :
				if( f.startsWith( "_" ) ) {
					//..
				} else {
					var i = f.lastIndexOf(".");
					if( i == -1 ) {
						trace("iiiiiiiiiiiiiiiiiiiiiiiiiiiiiii");
						continue;
					} else {
						var ext = f.substr( i+1 );
						switch( ext ) {
						case "xml" :
							var tpl = new Template( File.getContent(fp) );
							var ctx : Dynamic = getBaseContext();
							var _posts : Array<Dynamic> = ctx.posts;
							for( p in _posts )
								p.content = StringTools.htmlEscape( p.content );
							writeFile( path_dst+f, tpl.execute( ctx ) );
						case "html" :
							var site = parseSite( path, f );
							var tpl = new Template( site.content );
							var ctx = getBaseContext();
							var content = tpl.execute( ctx );
							ctx = getBaseContext();
							ctx.content = content;
							writeSite( path_dst+f, ctx );
						//case "css" :
						//	File.copy( fp, path_dst+f );
						default:
							File.copy( fp, path_dst+f );
						}
					}
				}
			case kdir:
				if( f.startsWith( "_" ) ) {
					//trace( "\t"+f );
					/*   
					switch( f.substr(1) ) {
					case "include":
						trace("TODO process include diectory" );
					//case "layout":
					case "posts":
						trace("TODO process posts");
					case "syndicate":
						trace("TODO process syndication" );
					default:
						warn( "Unkown cyberchrist directory ("+f+")" );
					}
					*/
				} else {
					var d = path_dst+f;
					if( !FileSystem.exists(d) )
						FileSystem.createDirectory( d );
					copyDataDirectory( f );
				}
			
			default :
			}
		}
	}
	
	static function processPosts( path : String ) {
		
		for( f in FileSystem.readDirectory( path ) ) {
			
			if( f.startsWith(".") )
				continue;
			if( !e_post_filename.match( f ) )
				error( "invalid post filename ["+f+"]" );
			
			var site : Dynamic = parseSite( path, f );
			if( site.layout == null ) site.layout = "post";
			site.content = panda.format( site.content );

			var post : Dynamic = {
				id : e_post_filename.matched(4),
				title : site.title,
				content : site.content, //new Template( site.content ).execute( {} )
				date : {
					year : e_post_filename.matched(1),
					month : e_post_filename.matched(2),
					day : e_post_filename.matched(3)
				}
			};
			
			var path = path_dst+post.date.year;
			if( !FileSystem.exists( path ) ) FileSystem.createDirectory( path );
			path = path+"/"+post.date.month;
			if( !FileSystem.exists( path ) ) FileSystem.createDirectory( path );
			path = path+"/"+post.date.day;
			if( !FileSystem.exists( path ) ) FileSystem.createDirectory( path );
			
			path = post.date.year+"/"+post.date.month+"/"+post.date.day+"/"+post.id+".html";
			
			post.path = path;
			posts.push( post );
		}
		
		posts.sort( function(a:Post,b:Post){
			if( a.date.year > b.date.year ) return -1;
			else if( a.date.year < b.date.year ) return 1;
			else {
				if( a.date.month > b.date.month ) return -1;
				else if( a.date.month < b.date.month ) return 1;
				else {
					if( a.date.day > b.date.day ) return -1;
					else if( a.date.month < b.date.day ) return 1;
				}
			}
			return 0;
		});
		
		for( p in posts ) {
			
			/*  
			var path = path_dst+p.date.year;
			if( !FileSystem.exists( path ) ) FileSystem.createDirectory( path );
			path = path+"/"+p.date.month;
			if( !FileSystem.exists( path ) ) FileSystem.createDirectory( path );
			path = path+"/"+p.date.day;
			if( !FileSystem.exists( path ) ) FileSystem.createDirectory( path );
			*/
			var ctx = attachContext( {}, p );
			var tpl = parseSite( path_src+"_layout", "post.html" );
			ctx.content = new Template( tpl.content ).execute( p  );
			writeSite( path_dst + p.path, ctx );
		}
	}
	
	static inline function writeSite( path : String, ctx : Dynamic ) {
		var t = tpl_site.execute( ctx );
		var a = new Array<String>();
		for( l in t.split("\n") ) {
			if( l.trim() != "" ) a.push(l);
		}
		t = a.join("\n");
		writeFile( path, t );
	}
	
	static function getBaseContext( ?attach : Dynamic ) : Dynamic {
		var _posts = posts;
		//var _archive : Array<Dynamic>;
		if( posts.length > 10 ) {
			//_archive = _posts.slice( 10 );
			_posts = _posts.slice( 0 );
		}
		//( posts.length > 10 ) ? posts.slice( 0, 10 ) : posts;
		var ctx = {
			now : Date.now().toString(),
			title : "disktree.net",
			url : "http://blog.disktree.net",
			posts : _posts,
			//_archive : 
			//description: "panzerkunst",
			//keywords : ["disktree","panzerkunst","art"]
		};
		if( attach != null )
			attachContext( ctx, attach );
		return ctx;
	}
	
	static function attachContext( a : Dynamic, b : Dynamic ) : Dynamic {
		for( f in Reflect.fields( b ) ) Reflect.setField( a, f, Reflect.field( b, f ) );
		return a;
	}
	
	static function run() {
		
		var timestart = haxe.Timer.stamp();
		
		tpl_site = new Template( File.getContent( path_src+'_layout/site.html' ) );
		posts = new Array();
		panda = new panda.Format( {
			path_img : "/img/",
			createLink : function(s){return s;}
		} );
		
		wipeDirectory( path_dst );
		
		processPosts( path_src+"_posts" );
		processDirectory( path_src );
		
		println( "\nOK, "+Std.int((haxe.Timer.stamp()-timestart)*1000)+"ms\n" );
	}
	
	static function error( ?info : String ) {
		if( info != null ) println( "ERROR: "+info );
		Sys.exit(0);
	}
	
	static function main() {
		
		println( "------- CyberChrist "+VERSION+" -------" );
		
		path_src = "src/";
		path_dst = "www/";
		
		//TODO read cl args
		
		//TODO read config file
		
		// test required files
		var requiredFiles = [
			path_src, path_dst,
			path_src+'_layout', path_src+'_layout/site.html'
		];
		var errors = new Array<String>();
		for( f in requiredFiles ) {
			if( !FileSystem.exists( f ) )
				errors.push( 'file missing:'+path_src+''+f+')' );
		}
		if( errors.length > 0 ) {
			println( "Holy shit! ERROR" );
			for( e in errors ) println( "\t"+e );
			Sys.exit(0);
		}
		
		run();
	}

}
