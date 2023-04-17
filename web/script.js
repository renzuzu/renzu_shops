

 async function SendData(data,cb) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (xhr.readyState == XMLHttpRequest.DONE) {
            if (data.msg == 'buy') {
                removeall()
            }
            if (cb) {
                cb(xhr.responseText)
            }
        }
    }
    xhr.open("POST", 'https://renzu_shops/nuicb', true)
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.send(JSON.stringify(data))
}
let getEl = function( id ) { return document.getElementById( id )}
let metadatas = undefined
let imgpath = ''
let itemids = {}
let uiopen = false
let position = 1;
let items = {}
let cart = {}
let shoptype = null
let show = false
let colorid = 1
let moneytype = 'money'
var content = {}
let lastshop = ''
let vImageCreator = undefined
window.addEventListener('message', function (table) {
    let event = table.data
    if (event.removecart) {
        remove(event.removecart.cartid,event.removecart.slotid)
    }
    if (event.displaybuy) {
        buydisplay({name : event.displaybuy.name, price: event.displaybuy.price, label: event.displaybuy.label})
    }
    if (event.stats) {
        getEl('perf').style.display = 'block';
        for(var [k,v] of Object.entries(event.stats)){
            if (k == 'label') {
                getEl(k).innerHTML = v;
            } else {
                if (v >= 100) { v = 100 }
                getEl(k).style.width = ''+v+'%';
            }
        }
    } else if (event.stats == false) {
        getEl('perf').style.display = 'none';
    }
    if (event.data?.type == 'bubble' && content[event.data?.id] == undefined) {
        let ui = `<div class="bubble-speech bubble-left" id="${event.data.id}" style=" position: absolute; left:`+event.data.x * 100+`%;top:`+event.data.y * 100+`%; ">
        <div class="progresscustomer" id="prog_${event.data.id}"></div>
		<h2 class="author">
		${event.data.title}
		</h2>
		<div class="message">
			${event.data.message}
		</div>
		</div>`
        content[event.data.id] = ui
        document.querySelector('.bubbledata').insertAdjacentHTML("beforeend", content[event.data.id])
    } else if (event.data?.type == 'bubble') {
        getEl(event.data.id).style.left = ''+event.data.x * 100+'%';
        getEl(event.data.id).style.top = ''+event.data.y * 100+'%';
        getEl('prog_'+event.data.id).style.width = 100 - event.data.wait+'%'
    } else if ( event.data?.type == 'bubbleremove') {
        getEl(event.data.id).remove()
        delete content[event.data.id]
    }
    if (event.data?.open) {
        getEl('pay').style.display = event.data.duty && 'none' || 'block'
        vImageCreator = event.data.vImageCreator
        getEl('shop').style.display = 'block'
        uiopen = true
        imgpath = event.data.imgpath
        getEl('shopname').innerHTML = event.data.label
        if (lastshop !== event.data.label) { removeall() }
        lastshop = event.data.label
        moneytype = event.data.moneytype || 'money'
        getEl('metadatas').style.display = 'none'
        getEl('moneytype').innerHTML = moneytype
        getEl('moneyimage').innerHTML = `${event.data.itemtype ? `<img src="${imgpath}${moneytype}.png" style="height:30px;">` : '<i class="fas fa-wallet" aria-hidden="true"></i>'}`
        getEl('money').innerHTML = event.data.wallet['money']
        getEl('bank').innerHTML = event.data.wallet['bank']

        shoptype = event.data.type
        position = 1
        if (event.data.type == 'VehicleShop') {
            getEl('shopbox').style.display = 'flex'
            getEl('mainshop').style.height = 'unset'
            getEl('shopbox').style.height = 'unset'
            getEl('mainshop').style.bottom = '0'
            getEl('mainshop').style.overflowY = 'unset'
            getEl('mainshop').style.overflowX = 'hidden'
            getEl('mainshop').style.position = 'absolute'
            getEl('shop').style.background = '#0e101200'
            getEl('vehicle').style.display = 'block'
            getEl('unggoy').style.display = 'block'
            show = false
            getEl('testdrive').style.display = 'block'
            SendData({type:1, items:1, msg : 'vehicle'})
        } else {
            getEl('testdrive').style.display = 'none'
            getEl('shopbox').style.display = 'grid'
            getEl('shopbox').style.height = '80vh'
            getEl('shopbox').style.transform = 'translateX(0px)'
            getEl('mainshop').style.bottom = 'unset'
            getEl('mainshop').style.overflowX = 'unset'
            getEl('mainshop').style.overflowY = 'scroll'
            getEl('mainshop').style.position = 'unset'
            getEl('shop').style.background = '#0e1012c7'
            getEl('vehicle').style.display = 'none'
            getEl('unggoy').style.display = 'none'
        }
        LoadCategory(event.data.shop)
        ShopItems(event.data.shop)
    } else if (event.data?.open == false) {
        getEl('shop').style.display = 'none'
        uiopen = false
    }
})

let totalamount = 0

function totalitem() {
    var total = 0
    for (const i in cart) {
        total += cart[i].count
    }
    getEl('totalitem').innerHTML = total
}

function totalitemprice(item) {
    var total = 0
    for (const i in cart) {
        total += Number(cart[i].count) * Number(cart[i].data.price)
    }
    return total
}

function remove(cartid,item) {
    getEl(cartid+"_cart").remove()
    totalamount -= items[item].price * cart[cartid].count
    getEl('totalamount').innerHTML = totalamount
    cart[cartid] = undefined
    delete cart[cartid];
    totalitem()
    SendData({cart:cart, msg : 'playercarts'})
}

function removeall(item) {
    getEl("cart").innerHTML = ''
    totalamount = 0
    getEl('totalamount').innerHTML = totalamount
    cart = {}
    totalitem()
    SendData({cart:cart, msg : 'playercarts'})
}

function minus(cartid,item) {
    if (cart[cartid].count <= 0) { return }
    cart[cartid].count -= 1
    getEl(cartid+'_amount').value = cart[cartid].count
    getEl(cartid+'_total').innerHTML = cart[cartid].count * items[item].price
    totalamount -= items[item].price
    getEl('totalamount').innerHTML = totalamount
    totalitem()
    SendData({cart:cart, msg : 'playercarts'})
}

function plus(cartid,item) {
    cart[cartid].count += 1
    getEl(cartid+'_amount').value = cart[cartid].count
    getEl(cartid+'_total').innerHTML = cart[cartid].count * items[item].price
    totalamount += items[item].price
    getEl('totalamount').innerHTML = totalamount
    totalitem()
    SendData({cart:cart, msg : 'playercarts'})
}

function pay() {
    SendData({items:cart, msg : 'buy'})
}

function buydisplay(data) {
    cart = {}
    cart[cartid] = {slotid: 1, count : 1, data : {name : data.name, price: data.price, label : data.label}, vehicle: {livery: -1, color: colorid, liverymod: -1}, metadatas: {}}
    SendData({items:cart, msg : 'buy'})
}

function testdrive() {
    SendData({vehicle:{ model : currentselection, liveries: liveryid || -1, colorid: colorid }, msg : 'testdrive'})
}

function CloseModal() {
    getEl('metadatas').style.display = 'none'
    metadatas = undefined
}

let liveries = {}
let liverymod = false
let itemcustomise = undefined
let currentselection = undefined
function ItemCallback(model,index) {
    liveryid = -1
    if (shoptype == 'VehicleShop') {
        currentselection = model
        SendData({model:model, msg : 'vehicleview'}, function(cb){
            let data = JSON.parse(cb)
            liveries = data.livery
            colorid = data.color
            liverymod = data.liverymod
            getEl('liveryid').style.display = 'inline-flex'
            getEl('livery').value = 'Default'
            let max = 0
            liveries[-1] = 'Default'
            for (const i in liveries) {
                max = max + 1
            }
            if (max == 1) {
                getEl('liveryid').style.display = 'none'
            }
            getEl('livery').setAttribute("max",max); // set a new value;
        })
    } else if (shoptype == 'BlackMarketArms' || shoptype == 'Ammunation') {
        getEl('metacontent').innerHTML = ''
        getEl('metaimg').src = `${imgpath}${model}.png`
        SendData({item:model, msg : 'getAvailableAttachments'}, function(cb){
            let data = JSON.parse(cb)
            if (!data[1]) { return }
            getEl('metadatas').style.display = 'block'
            itemcustomise = index
            metadatas = {}
            let metas = {}
            let c = 0
            for (const i in data) {
                var ui = `<input class="metainput" id="${data[i].name}" name="${data[i].name}" type="checkbox">
                <label class="metalabel" for="${data[i].name}">${data[i].label}</label>`
                getEl('metacontent').insertAdjacentHTML("beforeend", ui)
                var checkbox = document.querySelector(`input[name=${data[i].name}]`);
                checkbox.addEventListener('change', function() {
                    c += 1
                    if (this.checked) {
                        metadatas[itemids[data[i].name]] = data[i].name
                    } else {
                        delete metadatas[itemids[data[i].name]]
                    }
                });
            }
        })
    } else {
        getEl('metacontent').innerHTML = ''
        getEl('metaimg').src = `${imgpath}${model}.png`
        if (items[index].customise) {
            getEl('metadatas').style.display = 'block'
            itemcustomise = index
            metadatas = {}
            let metas = {}
            let c = 0
            for (const i in items[index].customise) {
                var name = items[index].customise[i]
                var ui = `<input class="metainput" id="${name}" name="${name}" type="checkbox">
                <label class="metalabel" for="${name}">${name}</label>`
                getEl('metacontent').insertAdjacentHTML("beforeend", ui)
                var checkbox = document.querySelector(`input[name=${name}]`);
                checkbox.addEventListener('change', function() {
                    c += 1
                    if (this.checked) {
                        metadatas[itemids[items[index].customise[i]]] = items[index].customise[i]
                    } else {
                        delete metadatas[itemids[items[index].customise[i]]]
                    }
                });
            }
        }
    }
}

async function CustomiseItem(data) {
    let meta = metadatas
    let myForm = getEl('customiseitems')
    let formData = new FormData(myForm);
    let gag = Object.fromEntries(formData)
    for (const i in gag) {
        if (i == 'amount') {
            amount = gag[i]
        }
    }
    const qty = await AddtoCart(itemcustomise,amount)
    for( var key in meta ) {
        await AddtoCart(key,qty)
    }
    metadatas = undefined
    CloseModal()
}

var cartid = 0

function table_matches(t1, t2) {
	let type1 = typeof(t1)
    let type2 = typeof(t2)
	if (type1 !== type2) { return false }
	if (type1 !== 'object' && type2 !== 'object') { return t1 == t2 }

    for (const i in t1) {
        let v2 = t2[i]
	    if (v2 == undefined || !table_matches(t1[i],v2)) { return false }
    }

    for (const i in t2) {
        let v1 = t1[i]
	    if (v1 == undefined || !table_matches(v1,t2[i])) { return false }
    }
	return true
}

function FindCartIDFromDefaultItem(data) {
    if (data.metadatas == undefined) {
        // try find existing cartid
        for (const i in cart) {
            if (cart[i].metadatas == undefined && cart[i].data.name == data.item.name && data.item.metadatas == undefined && 
                cart[i].data.name == data.item.name && table_matches(data.item.metadata || {}, cart[i].data.metadata || {})) {
                return i
            }
        }
    }
    return false
}

function VehicleImage(name,hash) {
    let image = `https://raw.githubusercontent.com/renzuzu/carmap/main/carmap/vehicle/`+name+`.jpg`
    if (vImageCreator && hash) {
        return vImageCreator[hash] || image
    } else {
        return image
    }
}

async function AddtoCart(item,qty) {
    var amount = 0
    let myForm = getEl(item)
    if (!qty) {
        let formData = new FormData(myForm);
        let gag = Object.fromEntries(formData)
        for (const i in gag) {
            if (i == 'amount') {
                amount = gag[i]
            }
        }
    }
    if (qty>0) { amount = qty }
    if (items[item].stock <= 0) { if (metadatas) {delete metadatas[item]}; return SendData({item:items[item].name, amount:amount, msg : 'outofstock'}) }
    if (amount == 0 || !Number(amount)) { amount = 1 }
    if (amount > items[item].stock) { if (metadatas) {delete metadatas[item]}; return SendData({item:items[item].name, amount:amount, msg : 'limitreached'}) }
    let findcartid = FindCartIDFromDefaultItem({item : items[item], metadatas: metadatas})
    cartid = findcartid !== false && findcartid || cartid+1
    if (cart[cartid]) {
        cart[cartid].count += parseInt(amount)
        amount = cart[cartid].count
    } else {
        cart[cartid] = {serialid: {slotid : item, cartid: cartid}, slotid: item, count : parseInt(amount), data : items[item], vehicle: {livery: liveryid, color: colorid, liverymod: liverymod}, metadatas: metadatas}
    }
    var totalprice = items[item].price * parseInt(cart[cartid].count)
    totalamount = totalitemprice(item)
    getEl('totalamount').innerHTML = totalamount
    if (getEl(cartid+'_cart')) {
        getEl(cartid+"_cart").remove()
    }
    totalitem()
    var customise = `<p class="customise">Customise</p>`
    var addons = `<p class="addons">Addon</p>`
    if (metadatas == undefined) {
        customise = ''
    } else {
        qty = undefined
    }
    if (qty == undefined) {
        addons = ''
    }
    metadatas = undefined
    var ui = `
            <tr class="cartitem" id="${cartid}_cart">
                <td>
                    <button class="prdct-delete" onclick="remove('${cartid}','${item}')">
                        <i class="fa fa-trash-alt" aria-hidden="true"></i>
                    </button>
                </td>
                <td>
                    <div class="product-img">
                        <img id="${cartid}_cartimg" src="${imgpath}${items[item].name}.png" alt="" onerror="this.src=VehicleImage('${items[item].name}','${items[item].hash || ''}');this.onerror=defaultimg(this)">
                    </div>
                </td>
                <td>
                    <div class="product-name">
                        <p>${items[item].label}</p>
                        ${customise}
                        ${addons}
                    </div>
                </td>
                <td>${items[item].price} $</td>
                <td>
                    <div class="prdct-qty-container">
                        <button class="prdct-qty-btn" type="button" onclick="minus('${cartid}','${item}')">
                            <i class="fa fa-minus" aria-hidden="true"></i>
                        </button>
                        <input id = "${cartid}_amount" type="text" name="qty" class="qty-input-box" disabled="" value="${amount}">
                        <button class="prdct-qty-btn" type="button">
                            <i class="fa fa-plus" aria-hidden="true" onclick="plus('${cartid}','${item}')"></i>
                        </button>
                    </div>
                </td>
                <td id="${cartid}_total" class="text-right">${totalprice} $</td>
            </tr>
     `
    getEl('cart').insertAdjacentHTML("beforeend", ui)
    SendData({item:cart[cartid].data.name, amount:amount, msg : 'cart'})
    SendData({cart:cart, msg : 'playercarts'})
    return amount
}

function fadeIn(el, time) {
    el.style.opacity = 0;
  
    var last = +new Date();
    var tick = function() {
      el.style.opacity = +el.style.opacity + (new Date() - last) / time+0.01;
      last = +new Date();
  
      if (+el.style.opacity < 1) {
        (window.requestAnimationFrame && requestAnimationFrame(tick)) || setTimeout(tick, 16)
      }
    };
  
    tick();
}

const delay = n => new Promise(r => setTimeout(r, n));
let shopdata = {}
async function ShopCats(cat) {
    getEl('shopbox').style.transform = 'translateX(0px)'
    position = 1
    return ShopItems(shopdata, cat)
}

let catimg = {}
async function ShowCats(i) {
    //for (const i in cats) {
        if (!getEl('all')) {
            let all = `<div id="all" class="category">
            <a href="#" onclick="ShopCats()" style="position: relative;
            top: 20px;"><i style="font-size: 2.5vh;" class="fa fa-store mr-2" aria-hidden="true"></i><br>
              <h2 style="padding: 20px;">
                All
              </h2>
            </a>
          </div>`
          getEl('cat').insertAdjacentHTML("beforeend", all)
        }
        var ui = `
        <div id="${i}_main" class="category">
            <a href="#" onclick="ShopCats('${i}')"><img id="${i}_cat" src="${imgpath}${catimg[i]}.png" onerror="this.src='${catimg[i]}';this.onerror=defaultimg(this)">
                <h2>
                    ${i} 
                </h2>
            </a>
        </div>
        `
        getEl('cat').insertAdjacentHTML("beforeend", ui)
        fadeIn(getEl(i+'_main'), 3000)
        await delay(100)
    //}
}

function makeid(length) {
    var result           = '';
    var characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    var charactersLength = characters.length;
    for ( var i = 0; i < length; i++ ) {
      result += characters.charAt(Math.floor(Math.random() * 
 charactersLength));
   }
   return result;
}

let validimage = {}
async function getImageSize(url,name) {
    const img = new Image();
    img.src = url;
    img.onload = function(){
        var height = img.height;
        var width = img.width;
        validimage[name] = img.src
        return width
        // code here to use the dimensions
    }
    var height = img.height;
    var width = img.width;
    return width
}

async function defaultimg(e,imgname) {
    const img = new Image();
    img.onerror = function() {
        if (getEl(e.id)) {
            getEl(e.id).src = shoptype == 'VehicleShop' && 'https://www.freeiconspng.com/uploads/vehicle-icon-png-car-sedan-4.png' || 'https://westerrands.websites.co.in/e-store/img/defaults/product-default.png'
        }
    }
    img.src = e.src;
}

let lastcat = null
async function LoadCategory(shop, cat) {
    await delay(100)
    for (const i in shop.inventory) {
        var data = shop.inventory[i]
        var imgname = data.name
        if (data.metadata) {
            imgname = data.metadata.image || data.name
        }
        if (data.category && !catimg[data.category] && !data.disable) {
            catimg[data.category] = imgname
            if (data.hash) {
                catimg[data.category] = vImageCreator[data.hash] || `https://raw.githubusercontent.com/renzuzu/carmap/main/carmap/vehicle/`+data.name+`.jpg`
            }
            ShowCats(data.category)
        }
    }
}

async function ShopItems(shop, cat) {
    if (cat == undefined) {
        lastcat = null
        shopdata = shop
        btnNext.style.opacity = "1";
        for (const i in shop.inventory) { // preload datas
            if (!uiopen) { break }
            var data = shop.inventory[i]
            items[i] = data
            itemids[data.name] = i
        }
    } else {
        lastcat = cat
    }

    getEl('shopbox').innerHTML = ''
    await delay(100)
    for (const i in shop.inventory) {
        if (!uiopen) { break }
        if (lastcat !== null && lastcat !== cat) { return }
        var data = shop.inventory[i]
        var enable = data.disable == false && cat == undefined
        var label = data.label
        var imgname = data.name
        var stock = data.stock
        if (stock == undefined) {
            stock = 'ꝏ'
        }
        if (data.metadata) {
            imgname = data.metadata.image || data.name
            label = data.metadata.label || data.label
        }
        if (enable || data.disable !== true && cat == data.category) {
            var iddiv = makeid(10)
            // items[i] = data
            let image = validimage[imgname] || `${imgpath}${imgname}.png`
            if (!show && shoptype == 'VehicleShop') { show = true; ItemCallback(data.name) }
            var addons = `<h2 class="customizable">⚙️ Addons</h2>`
            var component = ''
            if (!items[i].customise) {
                addons = ''
            }
            if (items[i].component) {
                component = `<h2 class="customizable">⚙️ Customise</h2>`
            }
            var ui = `
                <div id="${iddiv}_main" class="featured-item" style="position:relative;">
                <span>
                ${addons}
                ${component}
                <img class="aso" onclick="ItemCallback('${data.name}','${i}')" id="${iddiv}_img" src="${image}" onerror="this.src=VehicleImage('${imgname}','${items[i].hash || ''}');this.onerror = defaultimg(this);">
                    <h2>
                    ${label}
                    </h2>
                    <h3 style="color:lime;">
                    ${data.price}$
                    </h3>
                    <h3 id="stock">
                    Stock: <span>${stock}</span>
                    </h3>
                    <form style="display: inline-flex;" id="${i}">
                    <input id="amount" name="amount" placeholder="1" style="
                    width: 2.2vw;
                    text-align: center;
                    background: #3e4246;
                    color: #fff !important;
                    border-style: none;
                    border-radius: 7px;
                    border-style: ridge;
                    border-color: #6d737c;" type="number" max="${stock}" min="1">
                    <button onclick="event.preventDefault();AddtoCart('${i}')"><i class="fas fa-shopping-cart" aria-hidden="true"></i>Add</button>
                    </form>
                </span>
                </div>
            `
            getEl('shopbox').insertAdjacentHTML("beforeend", ui)
            getEl(iddiv+"_main").style.margin = '10px';
            getEl(iddiv+"_main").style.padding = '15px 20px';
            //getEl(iddiv+"_main").style.minWidth = '10vw';
            //getEl(iddiv+"_main").style.width = '10vw';
            if (shoptype == 'VehicleShop') {
                getEl(iddiv+'_img').style.width = '100%'
            } else {
                getEl(iddiv+'_img').style.width = '-webkit-fill-available'
            }
            fadeIn(getEl(iddiv+'_main'), 3000)
            await delay(100)
            let img = await getEl(iddiv+'_img') && getEl(iddiv+'_img').src || ''
            var imgwidth = await getImageSize(img,imgname)
            if (shoptype == 'VehicleShop' && imgwidth < 140 && getEl(iddiv+"_img")) {
                getEl(iddiv+"_img").style.minWidth = '7vw';
            }
        }
    }
    overflow = document.querySelector('.overflow');
    block = document.querySelector('.featured-item');
    allBlocks = document.querySelectorAll('.featured-item');
    if (block) {
        blockWidth = block.offsetWidth;
        maxWidth = overflow.offsetWidth;
        allBlocksWidth = allBlocks.length*blockWidth;
        if(allBlocksWidth+30 < maxWidth){
            btnPrevious.style.opacity = "0";
            btnNext.style.opacity = "0";
        } else {
            btnNext.style.opacity = "1";
        }
    } else {
        btnNext.style.opacity = "1";
    }
}

let btnNext = document.querySelector('.next');
let btnPrevious = document.querySelector('.previous');
let overflow = document.querySelector('.overflow');
let block = document.querySelector('.featured-item');
let allBlocks = document.querySelectorAll('.featured-item');
let blockWidth = 0
let maxWidth = 0;
let allBlocksWidth = 0
maxWidth = overflow.offsetWidth;
allBlocksWidth = allBlocks.length*blockWidth;
if(allBlocksWidth < maxWidth){
    btnPrevious.style.opacity = "0";
    btnNext.style.opacity = "0";
}

function togglePrev(position){
        overflow = document.querySelector('.overflow');
        block = document.querySelector('.featured-item');
        allBlocks = document.querySelectorAll('.featured-item');
        blockWidth = block.offsetWidth;


        maxWidth = overflow.offsetWidth;
        allBlocksWidth = allBlocks.length*blockWidth;
    if(position >= blockWidth){
        btnPrevious.style.opacity = "1";
    } else {
        btnPrevious.style.opacity = "0";
    }
}

function toggleNext(position){
        overflow = document.querySelector('.overflow');
        block = document.querySelector('.featured-item');
        allBlocks = document.querySelectorAll('.featured-item');
        blockWidth = block.offsetWidth;

        maxWidth = overflow.offsetWidth;
        allBlocksWidth = allBlocks.length*blockWidth*1.1;
    if((allBlocksWidth-position) > maxWidth){
        btnNext.style.opacity = "1";
    } else {
        btnNext.style.opacity = "0";
    }
}
btnNext.onclick = function(){
    if((allBlocksWidth-position) > maxWidth){
        position = position+blockWidth;
        overflow.style.transform = `translateX(-${position}px)`;
    }
    togglePrev(position);
    toggleNext(position);
}

btnPrevious.onclick = function(){
    if(position >= blockWidth){
    position = position-blockWidth;
    overflow.style.transform = `translateX(-${position}px)`;
    }
    togglePrev(position);
    toggleNext(position);
}
document.onkeyup = function (data) {
    if (data.keyCode == '27') {
        SendData({msg: 'close'})
        uiopen = false
        catimg = {}
        getEl('cat').innerHTML = ''
    }
    if (data.keyCode == '121') {
        SendData({msg: 'close'})
        uiopen = false
        catimg = {}
        getEl('cat').innerHTML = ''
    }
}

//document.body.className = "bg-dark";
var backgroundInfo = getEl("background-info");
var cpBackgroundColor = getEl("cp-background-color");
var cpBackgroundColors = cpBackgroundColor.getElementsByTagName("div");
var primaryContent = getEl("primary-content");
function changeColor(sender,color) {
    for (var i = 0; i < cpBackgroundColors.length; i++)
    cpBackgroundColors[i].classList.remove("active");
    SendData({color:color, msg: 'changecolor'})
    colorid = color
    sender.classList.add("active");
}
function rgbToHex(rgb) { 
    var hex = Number(rgb).toString(16);
    if (hex.length < 2)
        hex = "0" + hex;
    return hex;
}


addEventListenerAll('.btn-spn-up', 'click', event => this.spinUp(event))
addEventListenerAll('.btn-spn-down', 'click', event => this.spinDown(event))
  
let liveryid = -1
function spinUp(event) {
    var spinRoot = event.currentTarget.parentElement.parentElement  // .btn-spn
    var spinInput = spinRoot.children[1]    
    if (!spinInput.value || spinInput.value==="" || isNaN(parseInt(spinInput.value)))
    spinInput.value = 0
    var spinValue = parseInt(spinInput.value)
    var max = spinInput.getAttribute('max')
    if (!max || liveryid < max-2) {
        liveryid = liveryid+1
        spinInput.value = liveries[liveryid]
    } else {
        spinInput.value = liveries[liveryid]
    }
    SendData({livery:liveryid, msg: 'changelivery'})
}

function spinDown(event) {
    var spinRoot = event.currentTarget.parentElement.parentElement  // .btn-spn
    var spinInput = spinRoot.children[1]
    if (!spinInput.value || spinInput.value==="" || isNaN(parseInt(spinInput.value)))
    spinInput.value = 0
    var spinValue = parseInt(spinInput.value)

    var min = spinInput.getAttribute('min')
    if (!min || liveryid > min && liveries[liveryid] !== 0) {
        liveryid = liveryid-1
        spinInput.value = liveries[liveryid]
    } else {
        spinInput.value = 'Default'
    }
    SendData({livery:liveryid, msg: 'changelivery'})
}

function addEventListenerAll(selector, eventName, eventHandler) {
  var elements = document.querySelectorAll(selector)
  for(var i = 0; i<elements.length; i++) {
      elements[i].addEventListener(eventName, eventHandler) 
  }
}