
import neko.Lib;
import neko.Sys;
import neko.FileSystem;
import neko.io.File;
import haxe.Template;

using StringTools;

private typedef Page = {
	var title : String;
	var content : String;
}

private typedef PostDate = {
	var year : String;
	var month : String;
	var day : String;
}

private typedef Post = {
	var id : String;
	var date : PostDate;
	var title : String;
	var content : String;
	var path : String;
	//var tags : Array<String>;
}

/**
	Template fucker.
*/
class CyberChrist {
	
	static var EREG_filename = ~/^([0-9][0-9][0-9][0-9])-([0-9][0-9])-([0-9][0-9])-([a-zA-Z0-9_,!\.\-\?\(\)\+]+)$/;
	static var EREG_header = ~/^ *---(.+) *---(.+)$/ms;
	static var EREG_header_line = ~/^ *([a-zA-Z0-9_\/\.\-\s]+) *: *([a-zA-Z0-9!_,\/\.\-\?\(\)\s]+)/;
	
	static var path_src : String;
	static var path_dst : String;
	static var tpl_base : haxe.Template;
	static var tpl_post : haxe.Template;
	static var posts : Array<Post>;
	//static var wiki : panda.Wiki;
	static var panda : panda.Format;
	static var verbose = true;
	
	static inline function println( t : String ) Lib.println(t)
	
	static function writeFile( path : String, t : String ) {
		var f = File.write( path_dst+path, false );
		f.writeString( t );
		f.close();
	}
	
	static function wipeDirectory( path : String ) {
		for( f in FileSystem.readDirectory( path ) ) {
			if( path.startsWith(".") )
				continue;
			var p = path+"/"+f;
			switch( FileSystem.kind(p) ) {
			case kdir :
				wipeDirectory(p);
				FileSystem.deleteDirectory(p);
			case kfile :	
				FileSystem.deleteFile(p);
			default :
			}
		}
	}
	
	static function copyDirectory( src : String, dst : String ) {
		for( f in FileSystem.readDirectory( src ) ) {
			if( f.startsWith( "_" ) || f.startsWith( "." ) )
				continue;
			var s = src+"/"+f;
			var d = dst+"/"+f;
			switch( FileSystem.kind( s ) ) {
			case kdir :
				FileSystem.createDirectory( d );
				copyDirectory( s, d );
			case kfile :
				File.copy( s, d );
			default:	
			}
		}
	}
	
	static function parsePage( filepath : String ) : Page {
		if( !EREG_header.match( File.getContent( filepath ) ) )
			error( "invalid template name ["+filepath+"]" );
		var p : Page = cast {
			content : EREG_header.matched(2) //.trim()
		};
		var header = EREG_header.matched(1).trim();
		for( l in header.split("\n") ) {
			l = l.trim();
			if( EREG_header_line.match( l ) ) {
				var id = EREG_header_line.matched(1);
				var value = EREG_header_line.matched(2);
				switch( id ) {
				case "title" : p.title = value;
				}
			}
		}
		return p;
	}
	
	static function parsePost( path : String, filename : String ) : Post {
		
		if( !EREG_filename.match( filename ) )
			error( "invalid filename ["+filename+"]" );
		
		var filepath = path+"/"+filename;
		var p : Post = cast parsePage( filepath );
		p.id = EREG_filename.matched(4);
		p.date = {
			year : EREG_filename.matched(1),
			month : EREG_filename.matched(2),
			day : EREG_filename.matched(3)
		};
		
		return p;
	}
	
	static function writePost( p : Post ) {
		
		var path = path_dst+"/"+p.date.year;
		if( !FileSystem.exists( path ) ) FileSystem.createDirectory( path );
		path = path+"/"+p.date.month;
		if( !FileSystem.exists( path ) ) FileSystem.createDirectory( path );
		path = path+"/"+p.date.day;
		if( !FileSystem.exists( path ) ) FileSystem.createDirectory( path );
		
		path = "/"+p.date.year+"/"+p.date.month+"/"+p.date.day+"/"+p.id+".html";
		
		p.path = path;
		
		p.content = panda.format( p.content );
		
		var ctx : Dynamic = {
			content : p.content
		};
		var t = tpl_post.execute( ctx );
		
		ctx = {
			title : p.title,
			content : t
		};
		
		var out = tpl_base.execute( ctx );
		
		writeFile( path, out );

		//inform( "Post ["+path+"]");
	}
	
	static function printHelp() {
		println( "Usage: ...................." );
		Sys.exit(0);
	}
	
	static function error( info : String ) {
		println( "ERROR: "+info );
		Sys.exit(1);
	}
	
	//static var e_cli = ~/(\-\-?)([a-zA-Z]+) +([a-zA-Z0-9_\/]+)/;
	
	static function main() {
		
		var website_url = "http://192.168.0.110";
		
		path_src = "src";
		path_dst = "www";
		
		/*
		var args = Sys.args();
		var i = 0;
		var r = ~/(\-\-?)([a-zA-Z]+)/;
		while( i < args.length ) {
			var id = args[i];
			if( !r.match(id) ) {
				printHelp();
				return;
			}
			id = r.matched(2);
			var v = args[i+1];
			switch(id) {
			case "src" : path_src = v;
			case "dst" : path_dst = v;
			case "help" : printHelp(); return;
			default : printHelp(); return;
			}
			i += 2;
		}
		*/
		var cwd = Sys.getCwd();
		path_src = cwd+path_src;
		path_dst = cwd+path_dst;
		
		if( !FileSystem.exists( path_src ) ) error( "Source directory not found ["+Sys.getCwd()+"/"+path_src+"]" );
		if( !FileSystem.exists( path_dst ) ) error( "Destination directory not found ["+Sys.getCwd()+"/"+path_dst+"]" );
		
		println( "##################### CYBERCHRIST #####################" );
		println( "Reading from ["+path_src+"], printing to ["+path_dst+"]" );
		
		//TODO read config
		///........
		
		var timestamp = haxe.Timer.stamp();
		
		// wipe destination directory
		wipeDirectory( path_dst );
		
		tpl_base = new Template( File.getContent( path_src+"/_tpl/base.html" ) );
		tpl_post = new Template( File.getContent( path_src+"/_tpl/post.html" ) );
		
//		wiki = new panda.Wiki( { path_img : "/img/", cb_link : function(s){return s;} } );
		panda = new panda.Format( {
			path_img : "/img/",
			createLink : function(s){return s;}
		} );
		
		// copy files -----------
		copyDirectory( path_src, path_dst );
		
		// posts -----------
		posts = new Array();
		var path_posts = path_src+"/_posts";
		for( f in FileSystem.readDirectory( path_posts ) ) {
			posts.push( parsePost( path_posts, f ) );
		}
		posts.sort( function(a:Post,b:Post){
			if( a.date.year > b.date.year ) return 1;
			else if( a.date.year < b.date.year ) return -1;
			else {
				if( a.date.month > b.date.month ) return 1;
				else if( a.date.month < b.date.month ) return -1;
				else {
					if( a.date.day > b.date.day ) return 1;
					else if( a.date.month < b.date.day ) return -1;
				}
			}
			return 0;
		});
		posts.reverse();
		
		for( p in posts ) {
			//p.content = p.content.htmlEscape();
			writePost( p );
		}
		
		// write index.html -----------
		/*
		if( posts.length > 23 ) {
			posts = posts.slice( 0, 23 );
		}
		*/
		var ctx : Dynamic = {
			posts : posts
		};
		var p = parsePage( path_src+"/index.html" );
		var content = new Template( p.content ).execute( ctx );
		ctx = {
			title : p.title,
			content : content
		};
		writeFile( "/index.html", tpl_base.execute( ctx ) );
		
		// write atom.xml -----------
		//
		//for( p in posts ) p.content = p.content.trim();
		var ctx : Dynamic = {
			posts : posts,
			date : Date.now().toString(),
			website_url : website_url
		};
		var p = parsePage( path_src+"/atom.xml" );
		var content = new Template( p.content.trim() ).execute( ctx, { escape_xml : TemplateCallback.escape_xml } );
		writeFile( "/atom.xml", content );
		
		println( "Finished : [ POSTS:"+posts.length+", TIME:"+Std.int((haxe.Timer.stamp()-timestamp)*1000)+"ms ]" );
		println( "#######################################################" );
	}
    
}
