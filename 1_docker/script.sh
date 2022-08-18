#!/bin/bash

run_container() {
    # первым позиционным параметром можно передавать репозиторий 
    # пример run_container "repository/"
    # что бы можно было запускать контайнеры из локальных образов и из репозитория
    read -p 'Введи порт на котором должен отвечать контейнер: ' con_port
    readonly con_name="container_$image_name"

    docker container stop $con_name && docker container rm $con_name > /dev/null
    
    case $con_port in
            ''|*[!0-9]*) echo "Не корректный порт!"
                exit 1;;
                *) echo "Запускаю контейнер"
                docker run -d -p $con_port:80 --name $con_name ${1}${image_name};;
    esac
    sleep 2
    # проверка что контейнер успешно запустился
    $(docker ps | grep "$con_name" > /dev/null )
    if [ $? -eq 0 ]
    then
        echo "Контейнер $con_name успешно запущен"
    else
        echo "Произошла ошибка. Контейнер не запущен."
        exit 1
    fi
}

build_image() {
    read -p 'Введи имя образа: ' image_name

    if [ -z "$image_name" ]
    then
        echo "Имя образа не может быть пустой строкой"
        exit 1
    fi

    echo "Coздаем docker образ из Dockerfile"
    docker build --quiet -t $image_name .

    # проверяем что образ создался
    $(docker images | grep "$image_name" > /dev/null)
    if [ $? -eq 0 ]
    then
        echo "Образ $image_name успешно создан"
    else
        echo "Образ не создан"
        exit 1
    fi
}

is_logined() {
    $(docker system info | grep "Username" > /dev/null)
    return $?
}

login_to_hub() {
    for i in {1..3}
    do
        if is_logined
        then
            return 0
        else
            echo "Вы не залогинены на DockerHub"
            read -p "Введите ваш логин:" login
            read -s -p "Введите ваш пароль:" password
            $(docker login -u $login -p $password > /dev/null)
            if [ $? -eq 0 ]
            then
                echo "Удачно залогинелись"
                break
            else
                if [ "$i" -eq 3 ]; then exit 1; fi;
                echo "Ошибка входа, проверьте логин/пароль"
            fi
        fi
    done
}

push_image_to_hub() {
    login_to_hub
    read -p 'Введи имя репозитория в DockerHub: ' repository
    docker image tag $image_name $repository/$image_name
    docker push $repository/$image_name
}

clear_docker() {
    docker rm -f $(docker ps --format '{{.Names}}' | grep "$con_name")
    docker rmi $(docker images --format '{{.Repository}}' | grep "$image_name")
}


build_image

read -p "Хотите запустить контейнер образа $image_name (Y/N):" run_container
case $run_container in
    "yes" | "y" | "Y" ) 
        echo "Запускаем, контейнер"
        run_container ;;
    "no" | "n" | "N" )
        echo "Как хотите...";;
    * ) 
        echo "Не правильный ввод"
        exit 0;;
esac

read -p "Хотите запушить образ $image_name на dockerhub (Y/N):" pi
case $pi in
    "yes" | "y" | "Y" ) 
        echo "Заливаем образ $push_image на DockerHub"
        push_image_to_hub ;;
    "no" | "n" | "N" )
        echo "Как хотите...";;
    * ) 
        echo "Не правильный ввод"
        exit 0;;
esac

read -p "Удалить контейнеры и образ $image_name на localhost? (Y/N):" rmi
case $rmi in
    "yes" | "y" | "Y" ) 
        echo "Чистим localhost..."
        clear_docker ;;
    "no" | "n" | "N" )
        echo "Как хотите..."
        exit 0;;
    * ) 
        echo "Не правильный ввод"
        exit 0;;
esac

read -p "Запустить контейнер из DockerHub?" rr
case $rr in
    "yes" | "y" | "Y" ) 
        echo "Запускаем сонтейнер с DockerHub..."
        run_container "$repository/" ;;
    "no" | "n" | "N" )
        echo "Как хотите..."
        exit 0;;
    * ) 
        echo "Не правильный ввод"
        exit 0;;
esac












