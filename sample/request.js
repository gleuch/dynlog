/*

  Request a one or multiple files and display the sum result.

*/


var dynlog = {
  fetch_url: '',
  fetch_file_uuids: [],
  fetch_callback : 'dynlog.parse_stats',

  fetch : function() {
    for (i in this.fetch_file_uuids) {this.fetch_file_uuids[i] = 'file[]='+ this.fetch_file_uuids[i];}
    var uuids = this.fetch_file_uuids.join('&'), url = this.fetch_url +'?'+ uuids +'&callback='+ this.fetch_callback;
    document.write('<scr'+'ipt type="text/javascr'+'ipt" src="'+ url +'"></scr'+'ipt>');
  },

  parse_stats : function(obj) {
    var ct = 0;
    for(i in obj) {
      if (i != 'error' && obj[i] != null && obj[i]['requests_count'] != null) ct += parseInt(obj[i]['requests_count']);
    }
    document.write('Total request'+ (ct != 1 ? 's' : '') +': '+ ct)
  }

};

dynlog.fetch_url = 'http://yourdomain.com/info.json';
dynlog.fetch_file_uuids = ['abcdefghijkl', 'zyxwvutsrqpo'];
dynlog.fetch_callback = 'dynlog.parse_stats';

dynlog.fetch();